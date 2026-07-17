import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:marvel_travel/core/constants/api_config.dart';
import 'package:marvel_travel/features/auth/providers/auth_state.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("Handling a background message: ${message.messageId}");
}

class FcmService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
    'marvel_travel_channel',
    'Marvel Travel Notifications',
    description: 'Thông báo từ Marvel Travel',
    importance: Importance.high,
  );

  static Future<void> init() async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _requestPermission();
    await _initLocalNotifications();
    _listenForegroundMessages();
    _listenTokenRefresh();
  }

  static Future<void> _requestPermission() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  static Future<void> _initLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const settings = InitializationSettings(
      android: androidSettings,
    );

    await _localNotifications.initialize(settings);

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(_androidChannel);
  }

  static void _listenForegroundMessages() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      final android = message.notification?.android;

      if (notification == null || android == null) return;

      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannel.id,
            _androidChannel.name,
            channelDescription: _androidChannel.description,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
      );
    });
  }

  static void _listenTokenRefresh() {
    FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
      if (AuthState().isLoggedIn) {
        await registerCurrentDeviceToken(token);
      }
    });
  }

  static Future<String?> getToken() async {
    return _messaging.getToken();
  }

  static Future<void> registerCurrentDeviceToken([String? token]) async {
    if (!AuthState().isLoggedIn || AuthState().token == null) return;

    final fcmToken = token ?? await getToken();
    if (fcmToken == null || fcmToken.isEmpty) return;

    final response = await http.post(
      ApiConfig.uri('DeviceToken/register'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AuthState().token}',
      },
      body: jsonEncode({
        'token': fcmToken,
        'platform': 'Android',
      }),
    );

    if (response.statusCode != 200) {
      debugPrint('Không lưu được FCM token: ${response.statusCode}');
    }
  }

  static Future<void> unregisterCurrentDeviceToken() async {
    if (AuthState().token == null) return;

    final fcmToken = await getToken();
    if (fcmToken == null || fcmToken.isEmpty) return;

    await http.post(
      ApiConfig.uri('DeviceToken/unregister'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AuthState().token}',
      },
      body: jsonEncode({
        'token': fcmToken,
      }),
    );
  }
}
