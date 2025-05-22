import 'package:flutter/foundation.dart';

class NotificationSettings {
  final String username;
  final Map<String, bool> settings;
  final String? id;
  final List<dynamic> deviceSettings;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  NotificationSettings({
    required this.username,
    required this.settings,
    this.id,
    this.deviceSettings = const [],
    this.createdAt,
    this.updatedAt,
  });

  NotificationSettings copyWith({
    String? username,
    Map<String, bool>? settings,
    String? id,
    List<dynamic>? deviceSettings,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NotificationSettings(
      username: username ?? this.username,
      settings: settings ?? Map<String, bool>.from(this.settings),
      id: id ?? this.id,
      deviceSettings: deviceSettings ?? List<dynamic>.from(this.deviceSettings),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    final Map<String, bool> settingsMap = {};
    if (json['settings'] is Map) {
      (json['settings'] as Map).forEach((key, value) {
        if (value is bool) {
          settingsMap[key] = value;
        }
      });
    }

    return NotificationSettings(
      username: json['username'] ?? '',
      settings: settingsMap,
      id: json['_id'],
      deviceSettings: json['device_settings'] ?? [],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'settings': settings,
      if (id != null) '_id': id,
      'device_settings': deviceSettings,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  // Create default settings
  factory NotificationSettings.defaultSettings(String username) {
    return NotificationSettings(
      username: username,
      settings: {
        'user_posted_piece': true,
        'user_made_piece_live': true,
        'user_listed_piece_for_sale': true,
        'user_made_offer': true,
        'user_liked_piece': true,
        'user_subscribed': true,
      },
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is NotificationSettings &&
        other.username == username &&
        mapEquals(other.settings, settings) &&
        other.id == id &&
        listEquals(other.deviceSettings, deviceSettings);
  }

  @override
  int get hashCode =>
      username.hashCode ^
      settings.hashCode ^
      id.hashCode ^
      deviceSettings.hashCode;
}
