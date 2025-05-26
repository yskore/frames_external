import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frames_app/providers/feed_provider.dart';
import 'package:frames_app/providers/notification_provider.dart';
import 'package:frames_app/ui/Widgets/feed_components.dart';
import 'package:frames_app/ui/Widgets/notification_components.dart';
import 'package:frames_app/ui/screens/notification_settings_screen.dart';

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
          NotificationsTabContent(notifications: notifications),
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
