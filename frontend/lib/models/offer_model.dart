enum OfferStatus {
  pending,
  accepted,
  rejected,
  cancelled,
  paymentSubmitted,
  completed,
  disputed
}

enum PieceStatus { available, inProgress, sold }

class DisputeInfo {
  final String? openedBy;
  final String? reason;
  final DateTime? openedAt;
  final DateTime? resolvedAt;
  final String? resolution;

  DisputeInfo({
    this.openedBy,
    this.reason,
    this.openedAt,
    this.resolvedAt,
    this.resolution,
  });

  factory DisputeInfo.fromJson(Map<String, dynamic> json) {
    return DisputeInfo(
      openedBy: json['opened_by'],
      reason: json['reason'],
      openedAt:
          json['opened_at'] != null ? DateTime.parse(json['opened_at']) : null,
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'])
          : null,
      resolution: json['resolution'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'opened_by': openedBy,
      'reason': reason,
      'opened_at': openedAt?.toIso8601String(),
      'resolved_at': resolvedAt?.toIso8601String(),
      'resolution': resolution,
    };
  }
}

class OfferModel {
  final String id;
  final String pieceId;
  final String? pieceTitle;
  final String buyer;
  final String seller;
  final double amount;
  final OfferStatus status;
  final PieceStatus pieceStatus;
  final DateTime createdAt;
  final DateTime? paymentDeadline;
  final DateTime? sellerConfirmationDeadline;
  final DateTime? sellerGraceDeadline;
  final DateTime? paymentSubmittedAt;
  final String? paymentProof;
  final String? message;
  final String? paymentDetails;
  final String? currency;
  final DisputeInfo? dispute;

  OfferModel({
    required this.id,
    required this.pieceId,
    this.pieceTitle,
    required this.buyer,
    required this.seller,
    required this.amount,
    required this.status,
    required this.pieceStatus,
    required this.createdAt,
    required this.paymentDetails,
    required this.currency,
    this.paymentDeadline,
    this.sellerConfirmationDeadline,
    this.sellerGraceDeadline,
    this.paymentSubmittedAt,
    this.paymentProof,
    this.message,
    this.dispute,
  });

  OfferModel copyWith({
    String? id,
    String? pieceId,
    String? pieceTitle,
    String? buyer,
    String? seller,
    double? amount,
    OfferStatus? status,
    PieceStatus? pieceStatus,
    DateTime? createdAt,
    DateTime? paymentDeadline,
    DateTime? sellerConfirmationDeadline,
    DateTime? sellerGraceDeadline,
    DateTime? paymentSubmittedAt,
    String? paymentProof,
    String? message,
    DisputeInfo? dispute,
    String? paymentDetails,
    String? currency,
  }) {
    return OfferModel(
      id: id ?? this.id,
      pieceId: pieceId ?? this.pieceId,
      pieceTitle: pieceTitle ?? this.pieceTitle,
      buyer: buyer ?? this.buyer,
      seller: seller ?? this.seller,
      paymentDetails: paymentDetails ?? this.paymentDetails,
      currency: currency ?? this.currency,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      pieceStatus: pieceStatus ?? this.pieceStatus,
      createdAt: createdAt ?? this.createdAt,
      paymentDeadline: paymentDeadline ?? this.paymentDeadline,
      sellerConfirmationDeadline:
          sellerConfirmationDeadline ?? this.sellerConfirmationDeadline,
      sellerGraceDeadline: sellerGraceDeadline ?? this.sellerGraceDeadline,
      paymentSubmittedAt: paymentSubmittedAt ?? this.paymentSubmittedAt,
      paymentProof: paymentProof ?? this.paymentProof,
      message: message ?? this.message,
      dispute: dispute ?? this.dispute,
    );
  }

  factory OfferModel.fromJson(Map<String, dynamic> json) {
    return OfferModel(
      id: json['_id'] ?? '',
      paymentDetails: json['payment_details'],
      currency: json['currency'] ?? 'USD',
      pieceId: json['piece_id'] ?? '',
      pieceTitle: json['piece_title'],
      buyer: json['buyer'] ?? '',
      seller: json['seller'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      status: _parseOfferStatus(json['status'] ?? 'pending'),
      pieceStatus: _parsePieceStatus(json['piece_status'] ?? 'available'),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      paymentDeadline: json['payment_deadline'] != null
          ? DateTime.parse(json['payment_deadline'])
          : null,
      sellerConfirmationDeadline: json['seller_confirmation_deadline'] != null
          ? DateTime.parse(json['seller_confirmation_deadline'])
          : null,
      sellerGraceDeadline: json['seller_grace_deadline'] != null
          ? DateTime.parse(json['seller_grace_deadline'])
          : null,
      paymentSubmittedAt: json['payment_submitted_at'] != null
          ? DateTime.parse(json['payment_submitted_at'])
          : null,
      paymentProof: json['payment_proof'],
      message: json['message'],
      dispute: json['dispute'] != null
          ? DisputeInfo.fromJson(json['dispute'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'piece_id': pieceId,
      'pieceTitle': pieceTitle,
      'buyer': buyer,
      'seller': seller,
      'amount': amount,
      'status': _offerStatusToString(status),
      'piece_status': _pieceStatusToString(pieceStatus),
      'created_at': createdAt.toIso8601String(),
      'payment_deadline': paymentDeadline?.toIso8601String(),
      'seller_confirmation_deadline':
          sellerConfirmationDeadline?.toIso8601String(),
      'seller_grace_deadline': sellerGraceDeadline?.toIso8601String(),
      'payment_submitted_at': paymentSubmittedAt?.toIso8601String(),
      'payment_proof': paymentProof,
      'message': message,
      'dispute': dispute?.toJson(),
    };
  }

  static OfferStatus _parseOfferStatus(String status) {
    switch (status) {
      case 'accepted':
        return OfferStatus.accepted;
      case 'rejected':
        return OfferStatus.rejected;
      case 'cancelled':
        return OfferStatus.cancelled;
      case 'payment_submitted':
        return OfferStatus.paymentSubmitted;
      case 'completed':
        return OfferStatus.completed;
      case 'disputed':
        return OfferStatus.disputed;
      case 'pending':
      default:
        return OfferStatus.pending;
    }
  }

  static String _offerStatusToString(OfferStatus status) {
    switch (status) {
      case OfferStatus.accepted:
        return 'accepted';
      case OfferStatus.rejected:
        return 'rejected';
      case OfferStatus.cancelled:
        return 'cancelled';
      case OfferStatus.paymentSubmitted:
        return 'payment_submitted';
      case OfferStatus.completed:
        return 'completed';
      case OfferStatus.disputed:
        return 'disputed';
      case OfferStatus.pending:
        return 'pending';
    }
  }

  static PieceStatus _parsePieceStatus(String status) {
    switch (status) {
      case 'in_progress':
        return PieceStatus.inProgress;
      case 'sold':
        return PieceStatus.sold;
      case 'available':
      default:
        return PieceStatus.available;
    }
  }

  static String _pieceStatusToString(PieceStatus status) {
    switch (status) {
      case PieceStatus.inProgress:
        return 'in_progress';
      case PieceStatus.sold:
        return 'sold';
      case PieceStatus.available:
        return 'available';
    }
  }

  bool get isBuyer => true; // This would be implemented based on current user
  bool get isSeller => true; // This would be implemented based on current user

  bool get canBuyerTakeAction =>
      status == OfferStatus.accepted &&
      paymentDeadline != null &&
      DateTime.now().isBefore(paymentDeadline!);

  bool get canSellerTakeAction =>
      status == OfferStatus.paymentSubmitted &&
      sellerConfirmationDeadline != null &&
      DateTime.now().isBefore(sellerConfirmationDeadline!);

  bool get isExpiring {
    if (status == OfferStatus.accepted && paymentDeadline != null) {
      final difference = paymentDeadline!.difference(DateTime.now());
      return difference.inMinutes < 10 && difference.isNegative == false;
    }
    return false;
  }
}
