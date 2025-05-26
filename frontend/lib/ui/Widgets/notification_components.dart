import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frames_app/models/notification_model.dart';
import 'package:frames_app/providers/notification_provider.dart';
import 'package:intl/intl.dart';

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
