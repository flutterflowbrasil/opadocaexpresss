import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'app_notification_service.dart';

class MobileNotificationService implements AppNotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel entregasUrgente =
      AndroidNotificationChannel(
    'padoca_entregas_urgente',
    'Ofertas de entrega',
    description: 'Novas ofertas de despacho para o entregador',
    importance: Importance.max,
    playSound: true,
    sound: RawResourceAndroidNotificationSound('notificacoes_entregador'),
  );

  static const AndroidNotificationChannel pedidosUrgente =
      AndroidNotificationChannel(
    'padoca_pedidos_urgente',
    'Pedidos urgentes',
    description: 'Novos pedidos para o estabelecimento',
    importance: Importance.max,
  );

  static const AndroidNotificationChannel pedidos = AndroidNotificationChannel(
    'padoca_pedidos',
    'Pedidos',
    description: 'Atualizacoes de pedidos',
    importance: Importance.high,
  );

  static const AndroidNotificationChannel geral = AndroidNotificationChannel(
    'padoca_geral',
    'Geral',
    description: 'Notificacoes gerais da plataforma',
    importance: Importance.defaultImportance,
  );

  static const AndroidNotificationChannel legado = AndroidNotificationChannel(
    'padoca_express_channel',
    'Notificações Ôpadoca Express',
    description: 'Canal de notificações do Ôpadoca Express',
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

    await androidPlatform?.createNotificationChannel(entregasUrgente);
    await androidPlatform?.createNotificationChannel(pedidosUrgente);
    await androidPlatform?.createNotificationChannel(pedidos);
    await androidPlatform?.createNotificationChannel(geral);
    await androidPlatform?.createNotificationChannel(legado);
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
      'padoca_geral',
      'Geral',
      channelDescription: 'Notificacoes gerais da plataforma',
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
