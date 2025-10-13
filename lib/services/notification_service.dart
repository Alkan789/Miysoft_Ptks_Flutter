import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  bool _initialized = false;

  Future<void> initNotifications() async {
    if (_initialized) return;
    _initialized = true;

    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }

    const AndroidInitializationSettings initAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings =
    InitializationSettings(android: initAndroid);

    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    await flutterLocalNotificationsPlugin.initialize(initSettings);

    print("[NotificationService] initNotifications tamamlandı");
  }

  Future<void> showNotificationCustom(String title, String body) async {
    if (!_initialized) {
      print("[NotificationService] init edilmedi => skip");
      return;
    }

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'my_channel_id',
      'my_channel_name',
      channelDescription: 'my_channel_description',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );
    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformDetails,
    );
  }
}
