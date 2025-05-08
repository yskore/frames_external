class Piece {
  final String pieceid;
  final String pieceObject;
  final String pieceOwner;
  final String pieceTitle;
  final String frameName;
  final bool liveStatus;
  final int pieceLikes;
  final Map<String, dynamic>? pieceLocation;
  final String? pieceDescription;
  final DateTime pieceCreationDate;
  final String? pieceDisplay;
  final bool pieceForSale;
  final double piecePrice;
  final String ownership;
  final String? paymentDetails;
  final String currency;
  final int pieceImpressions;

  Piece({
    required this.pieceid,
    required this.pieceObject,
    required this.pieceOwner,
    required this.pieceTitle,
    required this.frameName,
    required this.liveStatus,
    required this.pieceLikes,
    this.pieceLocation,
    this.pieceDescription,
    this.paymentDetails,
    this.pieceImpressions = 0,
    required this.pieceCreationDate,
    this.pieceDisplay,
    required this.pieceForSale,
    required this.piecePrice,
    required this.ownership,
    required this.currency,
  });

  factory Piece.fromJson(Map<String, dynamic> json) {
    return Piece(
      pieceid: json['Piece_id'] ?? '',
      pieceObject: json['Piece_Object'] ?? '',
      pieceOwner: json['Piece_owner'] ?? '',
      pieceTitle: json['Piece_title'] ?? '',
      paymentDetails: json['payment_details'],
      frameName: json['Frame_name'] ?? 'not_found',
      liveStatus: json['live_status'] ?? false,
      pieceImpressions: json['Piece_impressions'] ?? 0,
      pieceLikes: json['Piece_likes'] ?? 0,
      pieceLocation: json['Piece_location'],
      currency: json['currency'] ?? 'USD',
      pieceDescription: json['Piece_description'],
      pieceCreationDate: json['Piece_creation_date'] != null
          ? DateTime.parse(json['Piece_creation_date'])
          : DateTime.now(),
      pieceDisplay: json['Piece_display'],
      pieceForSale: json['Piece_for_sale'] ?? false,
      piecePrice: (json['Piece_price'] ?? 0).toDouble(),
      ownership: json['ownership'] ?? '00',
    );
  }

  Piece copyWith({
    String? pieceid,
    String? pieceObject,
    String? pieceOwner,
    String? pieceTitle,
    String? frameName,
    bool? liveStatus,
    int? pieceLikes,
    Map<String, dynamic>? pieceLocation,
    String? pieceDescription,
    DateTime? pieceCreationDate,
    String? pieceDisplay,
    bool? pieceForSale,
    double? piecePrice,
    String? ownership,
    String? paymentDetails,
    String? currency,
    int? pieceImpressions,
  }) {
    return Piece(
      pieceid: pieceid ?? this.pieceid,
      pieceObject: pieceObject ?? this.pieceObject,
      pieceOwner: pieceOwner ?? this.pieceOwner,
      pieceTitle: pieceTitle ?? this.pieceTitle,
      frameName: frameName ?? this.frameName,
      liveStatus: liveStatus ?? this.liveStatus,
      pieceLikes: pieceLikes ?? this.pieceLikes,
      pieceLocation: pieceLocation ?? this.pieceLocation,
      pieceDescription: pieceDescription ?? this.pieceDescription,
      pieceCreationDate: pieceCreationDate ?? this.pieceCreationDate,
      pieceDisplay: pieceDisplay ?? this.pieceDisplay,
      pieceForSale: pieceForSale ?? this.pieceForSale,
      piecePrice: piecePrice ?? this.piecePrice,
      ownership: ownership ?? this.ownership,
      paymentDetails: paymentDetails ?? this.paymentDetails,
      currency: currency ?? this.currency,
      pieceImpressions: pieceImpressions ?? this.pieceImpressions,
    );
  }
}
