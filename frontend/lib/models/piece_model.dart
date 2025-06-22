class Piece {
  final String pieceid;
  final String pieceObject;
  final String pieceOwner;
  final String pieceTitle;
  final String frameName;
  final bool liveStatus;
  final int pieceLikes;
  final int pieceImpressions;
  final Map<String, dynamic>? pieceLocation;
  final String? pieceDescription;
  final DateTime pieceCreationDate;
  final String? pieceDisplay;
  final bool pieceForSale;
  final double piecePrice;
  final String ownership;
  final String? paymentDetails;
  final String currency;

  Piece({
    required this.pieceid,
    required this.pieceObject,
    required this.pieceOwner,
    required this.pieceTitle,
    required this.frameName,
    required this.liveStatus,
    required this.pieceLikes,
    required this.pieceImpressions,
    this.pieceLocation,
    this.pieceDescription,
    required this.pieceCreationDate,
    this.pieceDisplay,
    required this.pieceForSale,
    required this.piecePrice,
    required this.ownership,
    required this.currency,
    this.paymentDetails,
  });

  factory Piece.fromJson(Map<String, dynamic> json) {
    return Piece(
      // Handle both database format (Piece_id) and API format (id)
      pieceid: json['Piece_id'] ?? json['id'] ?? '',
      
      // Handle both database format (Piece_Object) and API format (pieceObject)
      pieceObject: json['Piece_Object'] ?? json['pieceObject'] ?? '',
      
      // Handle both database format (Piece_owner) and API format (owner)
      pieceOwner: json['Piece_owner'] ?? json['owner'] ?? '',
      
      // Handle both database format (Piece_title) and API format (title)
      pieceTitle: json['Piece_title'] ?? json['title'] ?? '',
      
      // Handle payment details
      paymentDetails: json['payment_details'] ?? json['paymentDetails'],
      
      // Handle both database format (Frame_name) and API format (frameName)
      frameName: json['Frame_name'] ?? json['frameName'] ?? 'not_found',
      
      // Handle both database format (live_status) and API format (isLive)
      liveStatus: json['live_status'] ?? json['isLive'] ?? false,
      
      // Handle both database format (Piece_likes) and API format (likes)
      pieceLikes: json['Piece_likes'] ?? json['likes'] ?? 0,
      
      // Handle both database format (Piece_impressions) and API format (impressions)
      pieceImpressions: json['Piece_impressions'] ?? json['impressions'] ?? 0,
      
      // Handle location
      pieceLocation: json['Piece_location'] ?? json['pieceLocation'],
      
      // Handle currency
      currency: json['currency'] ?? 'USD',
      
      // Handle both database format (Piece_description) and API format (description)
      pieceDescription: json['Piece_description'] ?? json['description'],
      
      // Handle creation date - support multiple formats
      pieceCreationDate: _parseDate(json['Piece_creation_date'] ?? json['creationDate']),
      
      // Handle both database format (Piece_display) and API format (imageUrl)
      pieceDisplay: json['Piece_display'] ?? json['imageUrl'],
      
      // Handle both database format (Piece_for_sale) and API format (forSale)
      pieceForSale: json['Piece_for_sale'] ?? json['forSale'] ?? false,
      
      // Handle both database format (Piece_price) and API format (price)
      piecePrice: (json['Piece_price'] ?? json['price'] ?? 0).toDouble(),
      
      // Handle ownership
      ownership: json['ownership'] ?? '00',
    );
  }

  // Helper method to parse dates from different formats
  static DateTime _parseDate(dynamic dateValue) {
    if (dateValue == null) return DateTime.now();
    
    if (dateValue is String) {
      try {
        return DateTime.parse(dateValue);
      } catch (e) {
        return DateTime.now();
      }
    }
    
    if (dateValue is DateTime) {
      return dateValue;
    }
    
    return DateTime.now();
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
