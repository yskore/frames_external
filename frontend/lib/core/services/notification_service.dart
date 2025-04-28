import 'dart:developer';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Define a callback type for token updates
typedef TokenUpdateCallback = Function(String token);

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  String? _token;
  TokenUpdateCallback? _onTokenUpdate;

  String? get token => _token;

  // Set a callback for token updates
  void setTokenUpdateCallback(TokenUpdateCallback callback) {
    _onTokenUpdate = callback;

    // If we already have a token, call the callback immediately
    if (_token != null) {
      callback(_token!);
    }
  }

  // Initialize notification settings and request permissions
  Future<void> initialize() async {
    try {
      // Request permission for iOS devices
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      log('User granted permission: ${settings.authorizationStatus}',
          name: 'NotificationService');

      // Initialize local notifications
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Configure foreground notification presentation options
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Get FCM token
      await refreshToken();

      // Listen for token refreshes
      _messaging.onTokenRefresh.listen((newToken) {
        _token = newToken;
        log('FCM Token refreshed: $_token', name: 'NotificationService');

        // Call the token update callback if set
        if (_onTokenUpdate != null && _token != null) {
          _onTokenUpdate!(_token!);
        }
      });

      // Handle incoming messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);
    } catch (e) {
      log('Error initializing notification service: $e',
          name: 'NotificationService');
    }
  }

  Future<void> refreshToken() async {
    try {
      _token = await _messaging.getToken();
      log('FCM Token: $_token', name: 'NotificationService');

      // Call the token update callback if set
      if (_onTokenUpdate != null && _token != null) {
        _onTokenUpdate!(_token!);
      }
    } catch (e) {
      log('Error getting FCM token: $e', name: 'NotificationService');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) async {
    log('Got foreground message: ${message.notification?.title}',
        name: 'NotificationService');

    // Display local notification
    if (message.notification != null) {
      await _showLocalNotification(message);
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    if (message.notification == null) return;

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'frames_notification_channel',
      'Frames Notifications',
      channelDescription: 'Notifications from Frames app',
      importance: Importance.max,
      priority: Priority.high,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      details,
      payload: message.data['route'],
    );
  }

  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null && response.payload!.isNotEmpty) {
      // Handle navigation based on payload
      log('Notification tapped with payload: ${response.payload}',
          name: 'NotificationService');
      // TODO: Navigate to the specific screen based on payload
    }
  }
}

// Required for background message handling
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  log('Handling background message: ${message.messageId}',
      name: 'BackgroundHandler');
}
