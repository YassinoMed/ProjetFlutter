import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // Request permissions
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Initialise Local Notifications
    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _localNotifications.initialize(initializationSettings);

    // Listen for foreground messages
    FirebaseMessaging.onMessage.listen(_handleMessage);

    // Get Token
    String? token = await _fcm.getToken();
    print('FCM Token: $token');
  }

  void _handleMessage(RemoteMessage message) {
    if (message.notification != null) {
      _showLocalNotification(
        message.notification!.title ?? '',
        message.notification!.body ?? '',
      );
    }
  }

  Future<void> _showLocalNotification(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'mediconnect_channel',
      'MediConnect Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );
    const notificationDetails = NotificationDetails(android: androidDetails);

    await _localNotifications.show(0, title, body, notificationDetails);
  }
}
