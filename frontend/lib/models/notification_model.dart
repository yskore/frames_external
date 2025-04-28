import 'package:flutter/foundation.dart';

enum NotificationType {
  offerReceived,
  offerAccepted,
  paymentSubmitted,
  paymentConfirmed,
  paymentDenied,
  paymentReminder,
  confirmationReminder,
  other
}

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final DateTime timestamp;
  final Map<String, dynamic> data;
  bool isRead;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.timestamp,
    required this.data,
    this.isRead = false,
  });

  NotificationModel copyWith({
    String? id,
    String? title,
    String? body,
    NotificationType? type,
    DateTime? timestamp,
    Map<String, dynamic>? data,
    bool? isRead,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
    );
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      type: parseNotificationType(json['type'] ?? 'other'),
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      data: json['data'] ?? {},
      isRead: json['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': notificationTypeToString(type),
      'timestamp': timestamp.toIso8601String(),
      'data': data,
      'isRead': isRead,
    };
  }

  // Made this method public instead of private
  static NotificationType parseNotificationType(String type) {
    switch (type) {
      case 'offer_received':
        return NotificationType.offerReceived;
      case 'offer_accepted':
        return NotificationType.offerAccepted;
      case 'payment_submitted':
        return NotificationType.paymentSubmitted;
      case 'payment_confirmed':
        return NotificationType.paymentConfirmed;
      case 'payment_denied':
        return NotificationType.paymentDenied;
      case 'payment_reminder':
        return NotificationType.paymentReminder;
      case 'confirmation_reminder':
        return NotificationType.confirmationReminder;
      default:
        return NotificationType.other;
    }
  }

  // Made this method public instead of private
  static String notificationTypeToString(NotificationType type) {
    switch (type) {
      case NotificationType.offerReceived:
        return 'offer_received';
      case NotificationType.offerAccepted:
        return 'offer_accepted';
      case NotificationType.paymentSubmitted:
        return 'payment_submitted';
      case NotificationType.paymentConfirmed:
        return 'payment_confirmed';
      case NotificationType.paymentDenied:
        return 'payment_denied';
      case NotificationType.paymentReminder:
        return 'payment_reminder';
      case NotificationType.confirmationReminder:
        return 'confirmation_reminder';
      case NotificationType.other:
        return 'other';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is NotificationModel &&
        other.id == id &&
        other.title == title &&
        other.body == body &&
        other.type == type &&
        other.timestamp == timestamp &&
        mapEquals(other.data, data) &&
        other.isRead == isRead;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        body.hashCode ^
        type.hashCode ^
        timestamp.hashCode ^
        data.hashCode ^
        isRead.hashCode;
  }
}
