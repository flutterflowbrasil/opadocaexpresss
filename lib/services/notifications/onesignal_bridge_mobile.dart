import 'package:flutter/foundation.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

import 'onesignal_bridge.dart';

class MobileOneSignalBridge implements OneSignalBridge {
  bool _initialized = false;
  bool _subscriptionObserver = false;
  bool _clickListener = false;

  @override
  Future<void> initialize(String appId) async {
    if (_initialized || appId.isEmpty) return;
    if (kDebugMode) {
      OneSignal.Debug.setLogLevel(OSLogLevel.warn);
    }
    OneSignal.initialize(appId);
    _initialized = true;
  }

  @override
  Future<void> login(String userId) async {
    await OneSignal.login(userId);
  }

  @override
  Future<void> logout() async {
    await OneSignal.logout();
  }

  @override
  Future<bool> requestPermission() async {
    if (OneSignal.Notifications.permission) return true;
    // false = não abre Ajustes sozinho (isso pausava a Activity e o watchdog
    // reportava ANR de 30s+ com o app em background).
    return OneSignal.Notifications.requestPermission(false);
  }

  @override
  Future<String?> subscriptionId() async {
    final id = OneSignal.User.pushSubscription.id;
    if (id == null || id.isEmpty) return null;
    return id;
  }

  @override
  void addSubscriptionObserver(void Function(String id) onChanged) {
    if (_subscriptionObserver) return;
    _subscriptionObserver = true;
    OneSignal.User.pushSubscription.addObserver((state) {
      final id = state.current.id;
      if (id == null || id.isEmpty) return;
      onChanged(id);
    });
  }

  @override
  void addClickListener(void Function(Map<String, dynamic> data) onClick) {
    if (_clickListener) return;
    _clickListener = true;
    OneSignal.Notifications.addClickListener((event) {
      final raw = event.notification.additionalData ?? <String, dynamic>{};
      onClick(Map<String, dynamic>.from(raw));
    });
  }
}

OneSignalBridge createOneSignalBridgeImpl() => MobileOneSignalBridge();
