import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frames_app/core/repositories/notification_repository.dart';
import 'package:frames_app/models/notification_model.dart';
import 'package:frames_app/models/notification_settings_model.dart' as NS;

// Provider for notification repository
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository();
});

// Provider for all notifications
final notificationsProvider =
    StateNotifierProvider<NotificationNotifier, List<NotificationModel>>((ref) {
  return NotificationNotifier(ref.read(notificationRepositoryProvider));
});

// Provider for unread notifications count
final unreadNotificationsCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationsProvider);
  return notifications.where((notification) => !notification.isRead).length;
});

// Provider for notification settings
final notificationSettingsProvider = StateNotifierProvider<
    NotificationSettingsNotifier, AsyncValue<NS.NotificationSettings?>>((ref) {
  return NotificationSettingsNotifier(ref.read(notificationRepositoryProvider));
});

class NotificationNotifier extends StateNotifier<List<NotificationModel>> {
  final NotificationRepository _notificationRepository;

  NotificationNotifier(this._notificationRepository) : super([]) {
    loadNotifications();

    // Listen for foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
  }

  Future<void> loadNotifications() async {
    final notifications = await _notificationRepository.getNotifications();
    state = notifications;
  }

  Future<void> markAsRead(String notificationId) async {
    await _notificationRepository.markNotificationAsRead(notificationId);
    state = [
      for (final notification in state)
        if (notification.id == notificationId)
          notification.copyWith(isRead: true)
        else
          notification,
    ];
  }

  Future<void> markAllAsRead() async {
    await _notificationRepository.markAllNotificationsAsRead();
    state = state
        .map((notification) => notification.copyWith(isRead: true))
        .toList();
  }

  Future<void> deleteNotification(String notificationId) async {
    await _notificationRepository.deleteNotification(notificationId);
    state = state
        .where((notification) => notification.id != notificationId)
        .toList();
  }

  Future<void> deleteAllNotifications() async {
    await _notificationRepository.deleteAllNotifications();
    state = [];
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification =
        await _notificationRepository.processReceivedNotification(message);

    // Add to state
    state = [notification, ...state];
  }

  // Process a background message that was clicked
  Future<void> processClickedMessage(RemoteMessage message) async {
    final notification =
        await _notificationRepository.processReceivedNotification(message);

    await markAsRead(notification.id);
    await loadNotifications();
  }
}

class NotificationSettingsNotifier
    extends StateNotifier<AsyncValue<NS.NotificationSettings?>> {
  final NotificationRepository _notificationRepository;

  NotificationSettingsNotifier(this._notificationRepository)
      : super(const AsyncValue.loading());

  Future<void> loadSettings(String username) async {
    state = const AsyncValue.loading();
    try {
      final localSettings =
          await _notificationRepository.getLocalNotificationSettings(username);
      if (localSettings != null) {
        state = AsyncValue.data(localSettings);
      }

      final serverSettings =
          await _notificationRepository.getNotificationSettings(username);
      if (serverSettings != null) {
        state = AsyncValue.data(serverSettings);
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> updateSettings(NS.NotificationSettings settings) async {
    try {
      state = AsyncValue.data(settings);

      await _notificationRepository.updateNotificationSettings(settings);
    } catch (e, stackTrace) {
      print('Error updating settings: $e');
    }
  }

  Future<void> toggleSetting(String key) async {
    final currentSettings = state.value;
    if (currentSettings != null) {
      final newSettings = Map<String, bool>.from(currentSettings.settings);
      newSettings[key] = !(newSettings[key] ?? true);

      final updatedSettings = currentSettings.copyWith(settings: newSettings);
      await updateSettings(updatedSettings);
    }
  }
}
