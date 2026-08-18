import 'onesignal_bridge.dart';

class StubOneSignalBridge implements OneSignalBridge {
  @override
  Future<void> initialize(String appId) async {}

  @override
  Future<void> login(String userId) async {}

  @override
  Future<void> logout() async {}

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<String?> subscriptionId() async => null;

  @override
  void addSubscriptionObserver(void Function(String id) onChanged) {}

  @override
  void addClickListener(void Function(Map<String, dynamic> data) onClick) {}
}

OneSignalBridge createOneSignalBridgeImpl() => StubOneSignalBridge();
