import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'app_notification_service.dart';

class WebNotificationService implements AppNotificationService {
  @override
  Future<void> init() async {}

  @override
  Future<bool> requestPermission() async {
    try {
      final permission =
          (await web.Notification.requestPermission().toDart).toDart;
      return permission == 'granted';
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> show({
    required String title,
    required String body,
  }) async {
    try {
      if (web.Notification.permission != 'granted') return;
      web.Notification(
        title,
        web.NotificationOptions(
          body: body,
          icon: '/icons/Icon-192.png',
        ),
      );
    } catch (_) {}
  }
}

AppNotificationService createNotificationServiceImpl() {
  return WebNotificationService();
}
