import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:frames_app/core/network/api_response.dart';
import 'package:frames_app/core/network/api_service.dart';
import 'package:frames_app/models/notification_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class NotificationRepository {
  final ApiService _apiService = ApiService();
  static const String _notificationsKey = 'user_notifications';
  final uuid = const Uuid();

  // Get all notifications from storage
  Future<List<NotificationModel>> getNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = prefs.getStringList(_notificationsKey) ?? [];

      return notificationsJson
          .map((json) => NotificationModel.fromJson(jsonDecode(json)))
          .toList()
        ..sort((a, b) => b.timestamp
            .compareTo(a.timestamp)); // Sort by timestamp, newest first
    } catch (e) {
      if (kDebugMode) {
        print('Error getting notifications: $e');
      }
      return [];
    }
  }

  // Save a notification to storage
  Future<bool> saveNotification(NotificationModel notification) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notifications = await getNotifications();

      // Check if notification with same ID already exists
      final existingIndex =
          notifications.indexWhere((n) => n.id == notification.id);

      if (existingIndex != -1) {
        // Update existing notification
        notifications[existingIndex] = notification;
      } else {
        // Add new notification
        notifications.add(notification);
      }

      // Save all notifications
      final notificationsJson = notifications
          .map((notification) => jsonEncode(notification.toJson()))
          .toList();

      return await prefs.setStringList(_notificationsKey, notificationsJson);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving notification: $e');
      }
      return false;
    }
  }

  // Mark notification as read
  Future<bool> markNotificationAsRead(String notificationId) async {
    try {
      final notifications = await getNotifications();
      final notificationIndex =
          notifications.indexWhere((n) => n.id == notificationId);

      if (notificationIndex != -1) {
        notifications[notificationIndex] =
            notifications[notificationIndex].copyWith(isRead: true);

        final prefs = await SharedPreferences.getInstance();
        final notificationsJson = notifications
            .map((notification) => jsonEncode(notification.toJson()))
            .toList();

        return await prefs.setStringList(_notificationsKey, notificationsJson);
      }

      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error marking notification as read: $e');
      }
      return false;
    }
  }

  // Mark all notifications as read
  Future<bool> markAllNotificationsAsRead() async {
    try {
      final notifications = await getNotifications();

      for (var i = 0; i < notifications.length; i++) {
        notifications[i] = notifications[i].copyWith(isRead: true);
      }

      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = notifications
          .map((notification) => jsonEncode(notification.toJson()))
          .toList();

      return await prefs.setStringList(_notificationsKey, notificationsJson);
    } catch (e) {
      if (kDebugMode) {
        print('Error marking all notifications as read: $e');
      }
      return false;
    }
  }

  // Delete a notification
  Future<bool> deleteNotification(String notificationId) async {
    try {
      final notifications = await getNotifications();
      notifications
          .removeWhere((notification) => notification.id == notificationId);

      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = notifications
          .map((notification) => jsonEncode(notification.toJson()))
          .toList();

      return await prefs.setStringList(_notificationsKey, notificationsJson);
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting notification: $e');
      }
      return false;
    }
  }

  // Delete all notifications
  Future<bool> deleteAllNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setStringList(_notificationsKey, []);
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting all notifications: $e');
      }
      return false;
    }
  }

  // Process a received push notification
  Future<NotificationModel> processReceivedNotification(
      RemoteMessage message) async {
    final notification = NotificationModel(
      id: message.messageId ?? uuid.v4(),
      title: message.notification?.title ?? 'New Notification',
      body: message.notification?.body ?? '',
      type: NotificationModel.parseNotificationType(
          message.data['notificationType'] ?? 'other'),
      timestamp: DateTime.now(),
      data: message.data,
      isRead: false,
    );

    await saveNotification(notification);
    return notification;
  }

  // Get unread notification count
  Future<int> getUnreadCount() async {
    final notifications = await getNotifications();
    return notifications.where((notification) => !notification.isRead).length;
  }

  // Update push token on the server
  Future<ApiResponse> updatePushToken(String username, String token) async {
    try {
      final response = await _apiService.post(
        'update-push-token',
        data: {
          'username': username,
          'push_token': token,
        },
      );

      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating push token: $e');
      }
      return ApiResponse.error('Failed to update push token: $e');
    }
  }
}
