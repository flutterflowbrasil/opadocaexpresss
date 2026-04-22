import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_notification_service_stub.dart'
    if (dart.library.io) 'app_notification_service_mobile.dart'
    if (dart.library.html) 'app_notification_service_web.dart';

abstract class AppNotificationService {
  Future<void> init();
  Future<bool> requestPermission();
  Future<void> show({
    required String title,
    required String body,
  });
}

AppNotificationService createNotificationService() => createNotificationServiceImpl();

final notificationServiceProvider = Provider<AppNotificationService>((ref) {
  return createNotificationService();
});
