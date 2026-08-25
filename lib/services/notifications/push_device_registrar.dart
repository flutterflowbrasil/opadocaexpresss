import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:padoca_express/core/onesignal/onesignal_config.dart';
import 'package:padoca_express/services/notifications/onesignal_service.dart';
import 'package:padoca_express/services/notifications/push_notification_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Vincula o usuario Supabase ao OneSignal (`external_id`) e grava o
/// subscription id em `dispositivos_push`.
class PushDeviceRegistrar {
  PushDeviceRegistrar._();

  static bool _syncing = false;
  static String? _usuarioId;
  static String? _lastLoginId;

  static PushNotificationRepository get _repository =>
      PushNotificationRepository(Supabase.instance.client);

  static String get plataforma {
    if (kIsWeb) return 'web';
    if (defaultTargetPlatform == TargetPlatform.iOS) return 'ios';
    return 'android';
  }

  static Future<void> sync() async {
    if (_syncing) return;
    if (!OneSignalConfig.isConfigured) return;

    _syncing = true;
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      _usuarioId = user.id;
      await OneSignalService.initialize();
      final bridge = OneSignalService.bridge;
      bridge.addSubscriptionObserver((id) {
        final usuarioId = _usuarioId;
        if (usuarioId == null) return;
        _upsert(usuarioId, id);
      });
      if (_lastLoginId != user.id) {
        await bridge.login(user.id);
        _lastLoginId = user.id;
      }
      // Não espera o diálogo de push — trava o dashboard e o ANR watchdog.
      unawaited(bridge.requestPermission());
      await _persistSubscription(user.id);
    } catch (e) {
      debugPrint('[PushDeviceRegistrar] OneSignal indisponivel: $e');
    } finally {
      _syncing = false;
    }
  }

  static Future<void> logout() async {
    if (!OneSignalConfig.isConfigured) return;
    try {
      final token = await OneSignalService.bridge.subscriptionId();
      if (token != null && token.isNotEmpty) {
        await _repository.deactivatePushDevice(token);
      } else if (_usuarioId != null) {
        await _repository.deactivateAllForUser(_usuarioId!);
      }
      await OneSignalService.bridge.logout();
    } catch (e) {
      debugPrint('[PushDeviceRegistrar] logout OneSignal: $e');
    } finally {
      _usuarioId = null;
      _lastLoginId = null;
    }
  }

  static Future<void> _persistSubscription(String usuarioId) async {
    final subscriptionId = await OneSignalService.bridge.subscriptionId();
    if (subscriptionId == null || subscriptionId.isEmpty) return;
    await _upsert(usuarioId, subscriptionId);
  }

  static Future<void> _upsert(String usuarioId, String subscriptionId) async {
    await _repository.upsertPushDevice(
      usuarioId: usuarioId,
      token: subscriptionId,
      plataforma: plataforma,
    );
  }
}
