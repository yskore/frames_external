class FlaggedPiece {
  final String pieceId;
  final String pieceTitle;
  final String pieceOwner;
  final String flagStatus;
  final String? flagType;
  final DateTime? flagExpiration;
  final String? disputeId;
  final DateTime? deletedAt;
  final DateTime creationDate;
  final bool liveStatus;

  FlaggedPiece({
    required this.pieceId,
    required this.pieceTitle,
    required this.pieceOwner,
    required this.flagStatus,
    this.flagType,
    this.flagExpiration,
    this.disputeId,
    this.deletedAt,
    required this.creationDate,
    required this.liveStatus,
  });

  factory FlaggedPiece.fromJson(Map<String, dynamic> json) {
    return FlaggedPiece(
      pieceId: json['Piece_id'] ?? '',
      pieceTitle: json['Piece_title'] ?? '',
      pieceOwner: json['Piece_owner'] ?? '',
      flagStatus: json['flag_status'] ?? 'normal',
      flagType: json['flag_type'],
      flagExpiration: json['flag_expiration'] != null
          ? DateTime.tryParse(json['flag_expiration'])
          : null,
      disputeId: json['dispute_id'],
      deletedAt: json['deleted_at'] != null
          ? DateTime.tryParse(json['deleted_at'])
          : null,
      creationDate: DateTime.tryParse(json['Piece_creation_date'] ?? '') ??
          DateTime.now(),
      liveStatus: json['live_status'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Piece_id': pieceId,
      'Piece_title': pieceTitle,
      'Piece_owner': pieceOwner,
      'flag_status': flagStatus,
      'flag_type': flagType,
      'flag_expiration': flagExpiration?.toIso8601String(),
      'dispute_id': disputeId,
      'deleted_at': deletedAt?.toIso8601String(),
      'Piece_creation_date': creationDate.toIso8601String(),
      'live_status': liveStatus,
    };
  }

  // Helper method to get human-readable flag status
  String get flagStatusDisplay {
    switch (flagStatus) {
      case 'normal':
        return 'Normal';
      case 'pending_action':
        return 'Pending Action';
      case 'disputed':
        return 'Disputed';
      case 'resolved':
        return 'Resolved';
      case 'deleted':
        return 'Deleted';
      default:
        return 'Unknown';
    }
  }

  // Helper method to get human-readable flag type
  String get flagTypeDisplay {
    switch (flagType) {
      case 'IN':
        return 'Inappropriate';
      case 'PI':
        return 'Piracy';
      default:
        return 'Unknown';
    }
  }

  // Helper method to check if flag is active
  bool get isActiveFlagged {
    return flagStatus == 'pending_action' || flagStatus == 'disputed';
  }

  // Helper method to check if piece is deleted
  bool get isDeleted {
    return flagStatus == 'deleted' || deletedAt != null;
  }

  // Helper method to check if flag is expired
  bool get isFlagExpired {
    if (flagExpiration == null) return false;
    return DateTime.now().isAfter(flagExpiration!);
  }
}
