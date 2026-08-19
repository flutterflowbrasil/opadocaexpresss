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

  Future<bool> ensurePermission({bool requestAlways = false}) async {
    if (!await Geolocator.isLocationServiceEnabled()) return false;

    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      return false;
    }

    if (requestAlways &&
        !kIsWeb &&
        perm == LocationPermission.whileInUse &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS)) {
      perm = await Geolocator.requestPermission();
    }

    return perm == LocationPermission.always ||
        perm == LocationPermission.whileInUse;
  }

  void startOnlineTracking(String entregadorId) {
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
  }

  Future<void> _publishOnlineLocation() async {
    final id = _entregadorId;
    if (id == null || !_keepOnline) return;
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        await _handleGpsFailure(id);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
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

  Future<void> _handleGpsFailure(String entregadorId) async {
    _gpsFailSince ??= DateTime.now();
    if (DateTime.now().difference(_gpsFailSince!) <
        const Duration(minutes: 5)) {
      return;
    }
    try {
      await Supabase.instance.client
          .from('entregadores')
          .update({'status_online': false}).eq('id', entregadorId);
    } catch (e) {
      debugPrint('[EntregadorGpsService] offline fallback: $e');
    }
    stop();
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
      startOnlineTracking(_entregadorId!);
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
