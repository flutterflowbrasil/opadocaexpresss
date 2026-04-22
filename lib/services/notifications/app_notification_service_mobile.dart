import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'app_notification_service.dart';

class MobileNotificationService implements AppNotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel =
      AndroidNotificationChannel(
    'padoca_express_channel',
    'Notificações Padoca Express',
    description: 'Canal de notificações do Padoca Express',
    importance: Importance.max,
  );

  @override
  Future<void> init() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

    const darwinInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const settings = InitializationSettings(
      android: androidInit,
      iOS: darwinInit,
      macOS: darwinInit,
    );

    await _plugin.initialize(settings);

    final androidPlatform = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlatform?.createNotificationChannel(_channel);
  }

  @override
  Future<bool> requestPermission() async {
    final androidPlatform = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    final iosPlatform = _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();

    final macPlatform = _plugin
        .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin>();

    bool granted = true;

    final androidGranted = await androidPlatform?.requestNotificationsPermission();
    if (androidGranted != null) granted = granted && androidGranted;

    final iosGranted = await iosPlatform?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
    if (iosGranted != null) granted = granted && iosGranted;

    final macGranted = await macPlatform?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
    if (macGranted != null) granted = granted && macGranted;

    return granted;
  }

  @override
  Future<void> show({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'padoca_express_channel',
      'Notificações Padoca Express',
      channelDescription: 'Canal de notificações do Padoca Express',
      importance: Importance.max,
      priority: Priority.high,
    );

    const darwinDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );
  }
}

AppNotificationService createNotificationServiceImpl() {
  return MobileNotificationService();
}
