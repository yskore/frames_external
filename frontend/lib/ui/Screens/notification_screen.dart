import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frames_app/models/feed_entry_model.dart';
import 'package:frames_app/models/notification_model.dart';
import 'package:frames_app/providers/feed_provider.dart';
import 'package:frames_app/providers/notification_provider.dart';
import 'package:frames_app/ui/screens/notification_settings_screen.dart';
import 'package:frames_app/ui/screens/other_user_profile_screen.dart';
import 'package:intl/intl.dart';

class NotificationScreen extends ConsumerStatefulWidget {
  final String username;

  const NotificationScreen({
    super.key,
    required this.username,
  });

  @override
  ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);

    // Load notification settings when screen is opened
    Future.delayed(Duration.zero, () {
      ref
          .read(notificationSettingsProvider.notifier)
          .loadSettings(widget.username);
    });
  }

  void _handleTabChange() {
    if (_tabController.index == 1 &&
        !ref.read(feedProvider.notifier).isInitialized) {
      ref.read(feedProvider.notifier).loadFeed(refresh: true);
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final notifications = ref.watch(notificationsProvider);
    final feedEntries = ref.watch(feedProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Notifications'),
            Tab(text: 'Feed'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Notification Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NotificationSettingsScreen(
                    username: widget.username,
                  ),
                ),
              );
            },
          ),
          // Show options menu based on current tab
          Consumer(
            builder: (context, ref, _) {
              // Only show options if there are items
              final hasItems = _tabController.index == 0
                  ? notifications.isNotEmpty
                  : feedEntries.isNotEmpty;

              if (!hasItems) return const SizedBox.shrink();

              return PopupMenuButton<String>(
                onSelected: (value) async {
                  if (_tabController.index == 0) {
                    // Notifications tab
                    if (value == 'mark_all_read') {
                      await ref
                          .read(notificationsProvider.notifier)
                          .markAllAsRead();
                    } else if (value == 'delete_all') {
                      _showDeleteAllConfirmation();
                    }
                  } else {
                    // Feed tab
                    if (value == 'mark_all_read') {
                      await ref.read(feedProvider.notifier).markAllAsRead();
                    }
                  }
                },
                itemBuilder: (BuildContext context) {
                  if (_tabController.index == 0) {
                    // Options for Notifications tab
                    return <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'mark_all_read',
                        child: ListTile(
                          leading: Icon(Icons.done_all),
                          title: Text('Mark all as read'),
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'delete_all',
                        child: ListTile(
                          leading: Icon(Icons.delete_sweep),
                          title: Text('Delete all'),
                        ),
                      ),
                    ];
                  } else {
                    // Options for Feed tab
                    return <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'mark_all_read',
                        child: ListTile(
                          leading: Icon(Icons.done_all),
                          title: Text('Mark all as read'),
                        ),
                      ),
                    ];
                  }
                },
              );
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Notifications Tab
          NotificationsTabContent(notifications: notifications),

          // Feed Tab
          FeedTabContent(feedEntries: feedEntries),
        ],
      ),
    );
  }

  void _showDeleteAllConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete All Notifications'),
          content: const Text(
              'Are you sure you want to delete all notifications? This cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete All'),
              onPressed: () async {
                Navigator.of(context).pop();
                await ref
                    .read(notificationsProvider.notifier)
                    .deleteAllNotifications();
              },
            ),
          ],
        );
      },
    );
  }
}

class NotificationsTabContent extends StatelessWidget {
  final List<NotificationModel> notifications;

  const NotificationsTabContent({
    super.key,
    required this.notifications,
  });

  @override
  Widget build(BuildContext context) {
    return notifications.isEmpty
        ? const Center(
            child: Text(
              'No notifications yet',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          )
        : ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return NotificationTile(notification: notification);
            },
          );
  }
}

class FeedTabContent extends ConsumerWidget {
  final List<FeedEntry> feedEntries;

  const FeedTabContent({
    super.key,
    required this.feedEntries,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isInitialized = ref.watch(feedProvider.notifier).isInitialized;

    // Show loading indicator while initially loading
    if (!isInitialized) {
      return const SizedBox.shrink();
    }

    if (feedEntries.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.rss_feed,
              size: 50,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Activity Feed',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Recent activity from people you follow will appear here',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    // Group feed entries by date
    final Map<String, List<FeedEntry>> groupedEntries = {};

    for (final entry in feedEntries) {
      final dateStr = _getDateKey(entry.createdAt);
      if (!groupedEntries.containsKey(dateStr)) {
        groupedEntries[dateStr] = [];
      }
      groupedEntries[dateStr]!.add(entry);
    }

    // Create flattened list with date headers
    final List<dynamic> flattenedList = [];
    final sortedDates = groupedEntries.keys.toList()
      ..sort((a, b) => b.compareTo(a)); // Sort dates in descending order

    for (final date in sortedDates) {
      flattenedList.add(_DateHeader(date: date));
      flattenedList.addAll(groupedEntries[date]!);
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(feedProvider.notifier).loadFeed(refresh: true);
      },
      child: ListView.builder(
        itemCount: flattenedList.length + 1, // +1 for load more indicator
        itemBuilder: (context, index) {
          if (index == flattenedList.length) {
            // Load more indicator at the bottom
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Center(
                child: TextButton(
                  onPressed: () {
                    ref.read(feedProvider.notifier).loadFeed();
                  },
                  child: const Text('Load More'),
                ),
              ),
            );
          }

          final item = flattenedList[index];

          if (item is _DateHeader) {
            return _buildDateHeader(context, item.date);
          } else {
            return FeedEntryTile(entry: item);
          }
        },
      ),
    );
  }

  // Helper method to convert DateTime to a consistent date string format
  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // Build a date header widget
  Widget _buildDateHeader(BuildContext context, String dateStr) {
    // Format date for display
    final DateTime date = DateTime.parse(dateStr);
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);

    String displayDate;
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      displayDate = 'Today';
    } else if (date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day) {
      displayDate = 'Yesterday';
    } else {
      displayDate = DateFormat('MMMM d, y').format(date);
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              displayDate,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }
}

// Helper class for the date headers in the list
class _DateHeader {
  final String date;
  _DateHeader({required this.date});
}

class FeedEntryTile extends ConsumerWidget {
  final FeedEntry entry;

  const FeedEntryTile({
    super.key,
    required this.entry,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: Key(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      onDismissed: (direction) {
        ref.read(feedProvider.notifier).deleteFeedEntry(entry.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Feed entry deleted')),
        );
      },
      child: ListTile(
        leading: entry.sourceAvatarUrl != null
            ? CircleAvatar(
                backgroundImage: NetworkImage(entry.sourceAvatarUrl!),
                radius: 20,
              )
            : const CircleAvatar(
                radius: 20,
                child: Icon(Icons.person),
              ),
        title: Text(
          entry.title,
          style: TextStyle(
            fontWeight: entry.read ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              entry.message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              _formatDate(entry.createdAt),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        tileColor: entry.read ? null : Colors.blue.withOpacity(0.05),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        onTap: () {
          if (!entry.read) {
            ref.read(feedProvider.notifier).markAsRead(entry.id);
          }

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OtherUserProfileScreen(
                username: entry.fromUsername,
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${_getRelativeTime(date)} · ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 30) {
      return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }
}

class NotificationTile extends ConsumerWidget {
  final NotificationModel notification;

  const NotificationTile({
    super.key,
    required this.notification,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      onDismissed: (direction) {
        ref
            .read(notificationsProvider.notifier)
            .deleteNotification(notification.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification deleted')),
        );
      },
      child: ListTile(
        leading: _getNotificationIcon(),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight:
                notification.isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification.body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('MMM d, y · h:mm a').format(notification.timestamp),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        tileColor: notification.isRead ? null : Colors.blue.withOpacity(0.05),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        onTap: () {
          if (!notification.isRead) {
            ref
                .read(notificationsProvider.notifier)
                .markAsRead(notification.id);
          }
          _showNotificationDetails(context, notification);
        },
      ),
    );
  }

  Widget _getNotificationIcon() {
    switch (notification.type) {
      case NotificationType.offerReceived:
        return CircleAvatar(
          backgroundColor: Colors.green.withOpacity(0.2),
          child: const Icon(Icons.local_offer, color: Colors.green),
        );
      case NotificationType.offerAccepted:
        return CircleAvatar(
          backgroundColor: Colors.blue.withOpacity(0.2),
          child: const Icon(Icons.check_circle, color: Colors.blue),
        );
      case NotificationType.paymentSubmitted:
      case NotificationType.paymentConfirmed:
        return CircleAvatar(
          backgroundColor: Colors.orange.withOpacity(0.2),
          child: const Icon(Icons.payment, color: Colors.orange),
        );
      case NotificationType.paymentDenied:
        return CircleAvatar(
          backgroundColor: Colors.red.withOpacity(0.2),
          child: const Icon(Icons.money_off, color: Colors.red),
        );
      case NotificationType.paymentReminder:
      case NotificationType.confirmationReminder:
        return CircleAvatar(
          backgroundColor: Colors.amber.withOpacity(0.2),
          child: const Icon(Icons.access_time, color: Colors.amber),
        );
      default:
        return CircleAvatar(
          backgroundColor: Colors.grey.withOpacity(0.2),
          child: const Icon(Icons.notifications, color: Colors.grey),
        );
    }
  }

  void _showNotificationDetails(
      BuildContext context, NotificationModel notification) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(notification.title),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(notification.body),
                const SizedBox(height: 16),
                Text(
                  DateFormat('MMMM d, y · h:mm a')
                      .format(notification.timestamp),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
                if (notification.type == NotificationType.offerReceived ||
                    notification.type == NotificationType.offerAccepted)
                  _buildOfferDetailsSection(notification),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            if (notification.data.containsKey('id') &&
                (notification.type == NotificationType.offerReceived ||
                    notification.type == NotificationType.paymentSubmitted))
              TextButton(
                child: const Text('View Details'),
                onPressed: () {
                  Navigator.of(context).pop();
                  // Navigate to offer details screen with the ID from notification data
                  // Navigator.push(context, MaterialPageRoute(builder: (context) =>
                  //   OfferDetailScreen(offerId: notification.data['id'])));
                },
              ),
          ],
        );
      },
    );
  }

  Widget _buildOfferDetailsSection(NotificationModel notification) {
    final data = notification.data;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const Text(
          'Offer Details:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (data['pieceTitle'] != null)
          _buildDetailRow('Piece', data['pieceTitle']),
        if (data['amount'] != null)
          _buildDetailRow('Amount', '\$${data['amount']}'),
        if (data['status'] != null)
          _buildDetailRow('Status', _capitalizeStatus(data['status'])),
        if (data['deadline'] != null)
          _buildDetailRow(
            'Deadline',
            DateFormat('MMM d, y · h:mm a')
                .format(DateTime.parse(data['deadline'])),
          ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _capitalizeStatus(String status) {
    return status.split('_').map((word) {
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }
}
