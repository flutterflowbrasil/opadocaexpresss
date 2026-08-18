import 'onesignal_bridge_stub.dart'
    if (dart.library.io) 'onesignal_bridge_mobile.dart'
    if (dart.library.html) 'onesignal_bridge_web.dart';

abstract class OneSignalBridge {
  Future<void> initialize(String appId);
  Future<void> login(String userId);
  Future<void> logout();
  Future<bool> requestPermission();
  Future<String?> subscriptionId();
  void addSubscriptionObserver(void Function(String id) onChanged);
  void addClickListener(void Function(Map<String, dynamic> data) onClick);
}

OneSignalBridge createOneSignalBridge() => createOneSignalBridgeImpl();
