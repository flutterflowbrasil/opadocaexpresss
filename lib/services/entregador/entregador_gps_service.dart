import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Rastreamento GPS do entregador: online (fila) e entrega ativa (foreground).
class EntregadorGpsService {
  EntregadorGpsService._();

  static final EntregadorGpsService instance = EntregadorGpsService._();

  StreamSubscription<Position>? _deliverySub;
  Timer? _onlineTimer;
  String? _entregadorId;
  bool _keepOnline = false;
  DateTime? _gpsFailSince;

  /// Chamado quando o app tira o entregador de online por falta de GPS.
  VoidCallback? onForcedOffline;

  static LocationSettings _deliverySettings() {
    if (kIsWeb) {
      return const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return AndroidSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
          foregroundNotificationConfig: const ForegroundNotificationConfig(
            notificationTitle: 'Entrega em andamento',
            notificationText: 'Rastreando sua rota',
            notificationChannelName: 'Entrega ativa',
            enableWakeLock: true,
          ),
        );
      case TargetPlatform.iOS:
        return AppleSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
          activityType: ActivityType.automotiveNavigation,
          pauseLocationUpdatesAutomatically: false,
          showBackgroundLocationIndicator: true,
        );
      default:
        return const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        );
    }
  }

  static LocationSettings _onlineSettings() {
    return const LocationSettings(
      accuracy: LocationAccuracy.medium,
      timeLimit: Duration(seconds: 8),
    );
  }

  Future<bool> ensurePermission({bool requestAlways = false}) async {
    return await gpsBlockReason(requestAlways: requestAlways) == null;
  }

  /// `null` se o GPS pode ser usado. Senão, texto para a UI.
  /// [prompt] false = só lê o status (boot do dashboard, sem diálogo).
  Future<String?> gpsBlockReason({
    bool requestAlways = false,
    bool prompt = true,
  }) async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return 'Ative o GPS do aparelho para ficar online.';
      }

      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        if (!prompt) {
          return 'Permita o acesso à localização para receber pedidos.';
        }
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied) {
        return 'Permita o acesso à localização para receber pedidos.';
      }
      if (perm == LocationPermission.deniedForever) {
        return 'Localização bloqueada. Toque em Ajustes e permita o acesso.';
      }

      if (prompt &&
          requestAlways &&
          !kIsWeb &&
          perm == LocationPermission.whileInUse &&
          (defaultTargetPlatform == TargetPlatform.android ||
              defaultTargetPlatform == TargetPlatform.iOS)) {
        perm = await Geolocator.requestPermission();
      }

      if (perm == LocationPermission.always ||
          perm == LocationPermission.whileInUse) {
        return null;
      }
      return 'Permita o acesso à localização para receber pedidos.';
    } catch (e) {
      debugPrint('[EntregadorGpsService] permission: $e');
      return 'Permita o acesso à localização para receber pedidos.';
    }
  }

  Future<void> openSettings() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      await Geolocator.openLocationSettings();
      return;
    }
    await Geolocator.openAppSettings();
  }

  /// Inicia o ping de localização. Devolve o motivo se não puder rastrear.
  Future<String?> startOnlineTracking(
    String entregadorId, {
    bool prompt = true,
  }) async {
    final reason = await gpsBlockReason(prompt: prompt);
    if (reason != null) return reason;

    _deliverySub?.cancel();
    _deliverySub = null;
    _onlineTimer?.cancel();
    _entregadorId = entregadorId;
    _keepOnline = true;
    _gpsFailSince = null;
    unawaited(_publishOnlineLocation());
    _onlineTimer = Timer.periodic(
      const Duration(seconds: 45),
      (_) => _publishOnlineLocation(),
    );
    return null;
  }

  Future<void> _publishOnlineLocation() async {
    final id = _entregadorId;
    if (id == null || !_keepOnline) return;

    if (!await Geolocator.isLocationServiceEnabled()) {
      await _forceOffline(id);
      return;
    }
    final perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      await _forceOffline(id);
      return;
    }

    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: _onlineSettings(),
      );
      _gpsFailSince = null;
      await Supabase.instance.client.from('entregador_localizacao_atual').upsert(
        {
          'entregador_id': id,
          'latitude': pos.latitude,
          'longitude': pos.longitude,
          'velocidade_kmh': (pos.speed * 3.6).clamp(0, 200),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        },
        onConflict: 'entregador_id',
      );

      await Supabase.instance.client.from('entregadores').update({
        'latitude': pos.latitude,
        'longitude': pos.longitude,
      }).eq('id', id);
    } catch (e) {
      debugPrint('[EntregadorGpsService] online location: $e');
      await _handleGpsFailure(id);
    }
  }

  Future<void> _forceOffline(String entregadorId) async {
    try {
      await Supabase.instance.client
          .from('entregadores')
          .update({'status_online': false}).eq('id', entregadorId);
    } catch (e) {
      debugPrint('[EntregadorGpsService] offline fallback: $e');
    }
    stop();
    onForcedOffline?.call();
  }

  Future<void> _handleGpsFailure(String entregadorId) async {
    _gpsFailSince ??= DateTime.now();
    if (DateTime.now().difference(_gpsFailSince!) <
        const Duration(minutes: 5)) {
      return;
    }
    await _forceOffline(entregadorId);
  }

  void startDeliveryTracking(void Function(Position) onPosition) {
    _onlineTimer?.cancel();
    _onlineTimer = null;
    _deliverySub?.cancel();
    _deliverySub = Geolocator.getPositionStream(
      locationSettings: _deliverySettings(),
    ).listen(onPosition, onError: (Object e) {
      debugPrint('[EntregadorGpsService] delivery stream: $e');
    });
  }

  /// Encerra o stream da entrega e, se o entregador ainda estiver online,
  /// volta o ping de 45s da fila.
  void stopDeliveryTracking() {
    _deliverySub?.cancel();
    _deliverySub = null;
    if (_keepOnline && _entregadorId != null) {
      unawaited(startOnlineTracking(_entregadorId!));
    }
  }

  void stop() {
    _keepOnline = false;
    _deliverySub?.cancel();
    _deliverySub = null;
    _onlineTimer?.cancel();
    _onlineTimer = null;
    _entregadorId = null;
    _gpsFailSince = null;
  }
}
