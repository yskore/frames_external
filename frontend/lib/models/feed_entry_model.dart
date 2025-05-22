class FeedEntry {
  final String id;
  final String forUsername;
  final String fromUsername;
  final String actionType;
  final String? referenceId;
  final String? pieceTitle;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  bool read;

  String? sourceAvatarUrl;

  FeedEntry({
    required this.id,
    required this.forUsername,
    required this.fromUsername,
    required this.actionType,
    this.referenceId,
    this.pieceTitle,
    required this.metadata,
    required this.createdAt,
    required this.read,
    this.sourceAvatarUrl,
  });

  FeedEntry copyWith({
    String? id,
    String? forUsername,
    String? fromUsername,
    String? actionType,
    String? referenceId,
    String? pieceTitle,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    bool? read,
    String? sourceAvatarUrl,
  }) {
    return FeedEntry(
      id: id ?? this.id,
      forUsername: forUsername ?? this.forUsername,
      fromUsername: fromUsername ?? this.fromUsername,
      actionType: actionType ?? this.actionType,
      referenceId: referenceId ?? this.referenceId,
      pieceTitle: pieceTitle ?? this.pieceTitle,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      read: read ?? this.read,
      sourceAvatarUrl: sourceAvatarUrl ?? this.sourceAvatarUrl,
    );
  }

  factory FeedEntry.fromJson(Map<String, dynamic> json) {
    return FeedEntry(
      id: json['_id'] ?? '',
      forUsername: json['for_username'] ?? '',
      fromUsername: json['from_username'] ?? '',
      actionType: json['action_type'] ?? '',
      referenceId: json['reference_id'],
      pieceTitle: json['piece_title'],
      metadata: json['metadata'] ?? {},
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      read: json['read'] ?? false,
      sourceAvatarUrl: null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'for_username': forUsername,
      'from_username': fromUsername,
      'action_type': actionType,
      'reference_id': referenceId,
      'piece_title': pieceTitle,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      'read': read,
    };
  }

  String get title {
    switch (actionType) {
      case 'posted_piece':
        return '${metadata['subscriberName'] ?? fromUsername} posted a new piece';
      case 'made_piece_live':
        return '${metadata['subscriberName'] ?? fromUsername} made a piece live';
      case 'listed_for_sale':
        return '${metadata['subscriberName'] ?? fromUsername} listed a piece for sale';
      case 'made_offer':
        return '${metadata['subscriberName'] ?? fromUsername} made an offer';
      case 'liked_piece':
        return '${metadata['subscriberName'] ?? fromUsername} liked a piece';
      case 'subscribed':
        return '${metadata['subscriberName'] ?? fromUsername} subscribed to ${metadata['targetName'] ?? metadata['targetUsername'] ?? referenceId}';
      case 'sold_piece':
        return '${metadata['subscriberName'] ?? fromUsername} sold a piece';
      case 'purchased_piece':
        return '${metadata['subscriberName'] ?? fromUsername} purchased a piece';
      default:
        return fromUsername;
    }
  }

  String get message {
    switch (actionType) {
      case 'subscribed':
        return 'Started following ${metadata['targetName'] ?? metadata['targetUsername'] ?? referenceId}';
      case 'posted_piece':
        return pieceTitle != null
            ? 'Posted: "$pieceTitle"'
            : 'Posted a new piece';
      case 'liked_piece':
        return pieceTitle != null ? 'Liked: "$pieceTitle"' : 'Liked a piece';
      default:
        return pieceTitle != null ? 'Piece: "$pieceTitle"' : '';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is FeedEntry &&
        other.id == id &&
        other.forUsername == forUsername &&
        other.fromUsername == fromUsername &&
        other.actionType == actionType;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        forUsername.hashCode ^
        fromUsername.hashCode ^
        actionType.hashCode;
  }
}
