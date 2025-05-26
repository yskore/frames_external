import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frames_app/models/feed_entry_model.dart';
import 'package:frames_app/providers/feed_provider.dart';
import 'package:frames_app/ui/screens/other_user_profile_screen.dart';
import 'package:intl/intl.dart';

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
