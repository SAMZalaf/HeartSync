import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BackgroundService {
  static final BackgroundService _instance = BackgroundService._internal();
  factory BackgroundService() => _instance;
  BackgroundService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    await _initializeLocalNotifications();
    await _initializeFirebaseMessaging();
    await _setupFirestoreListeners();
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  Future<void> _initializeFirebaseMessaging() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('✅ Notification permissions granted');
      
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        await _saveFcmToken(token);
        debugPrint('📱 FCM Token: $token');
      }

      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationOpened);
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    }
  }

  Future<void> _setupFirestoreListeners() async {
    final prefs = await SharedPreferences.getInstance();
    final myHeartCode = prefs.getString('userHeartCode');
    final partnerHeartCode = prefs.getString('partnerHeartCode');

    if (myHeartCode != null && partnerHeartCode != null) {
      FirebaseFirestore.instance
          .collection('interactions')
          .doc('${partnerHeartCode}_$myHeartCode')
          .snapshots()
          .listen((snapshot) {
        if (snapshot.exists) {
          final data = snapshot.data();
          if (data != null && data['type'] == 'heartbeat') {
            _showHeartbeatNotification();
          }
        }
      });
    }
  }

  Future<void> _saveFcmToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fcmToken', token);
    
    final myHeartCode = prefs.getString('userHeartCode');
    if (myHeartCode != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(myHeartCode)
          .set({'fcmToken': token}, SetOptions(merge: true));
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('📬 Foreground message: ${message.notification?.title}');
    
    if (message.notification != null) {
      await _showNotification(
        message.notification!.title ?? 'HeartSync',
        message.notification!.body ?? 'You have a new notification',
      );
    }
  }

  Future<void> _handleNotificationOpened(RemoteMessage message) async {
    debugPrint('🔔 Notification opened: ${message.data}');
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('🔔 Notification tapped: ${response.payload}');
  }

  Future<void> _showHeartbeatNotification() async {
    await _showNotification(
      '💕 Heartbeat Received',
      'Your partner sent you a heartbeat!',
      importance: Importance.high,
      priority: Priority.high,
    );
  }

  Future<void> _showNotification(
    String title,
    String body, {
    Importance importance = Importance.defaultImportance,
    Priority priority = Priority.defaultPriority,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'heartsync_channel',
      'HeartSync Notifications',
      channelDescription: 'Notifications for heartbeats and messages',
      importance: importance,
      priority: priority,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('🔥 Background message: ${message.notification?.title}');
}
