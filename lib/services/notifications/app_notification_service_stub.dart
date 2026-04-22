import 'app_notification_service.dart';

class _StubNotificationService implements AppNotificationService {
  @override
  Future<void> init() async {}

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<void> show({
    required String title,
    required String body,
  }) async {}
}

AppNotificationService createNotificationServiceImpl() {
  return _StubNotificationService();
}
