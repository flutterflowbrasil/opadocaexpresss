// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'app_notification_service.dart';

class WebNotificationService implements AppNotificationService {
  @override
  Future<void> init() async {}

  @override
  Future<bool> requestPermission() async {
    if (!html.Notification.supported) {
      return false;
    }

    final permission = await html.Notification.requestPermission();

    return permission == 'granted';
  }

  @override
  Future<void> show({
    required String title,
    required String body,
  }) async {
    if (!html.Notification.supported) return;

    if (html.Notification.permission != 'granted') return;

    html.Notification(
      title,
      body: body,
      icon: '/icons/Icon-192.png',
    );
  }
}

AppNotificationService createNotificationServiceImpl() {
  return WebNotificationService();
}
