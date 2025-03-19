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
    required this.pieceCreationDate,
    this.pieceDisplay,
    required this.pieceForSale,
    required this.piecePrice,
  });

  factory Piece.fromJson(Map<String, dynamic> json) {
    return Piece(
      pieceid: json['Piece_id'] ?? '',
      pieceObject: json['Piece_Object'] ?? '',
      pieceOwner: json['Piece_owner'] ?? '',
      pieceTitle: json['Piece_title'] ?? '',
      frameName: json['Frame_name'] ?? 'not_found',
      liveStatus: json['live_status'] ?? false,
      pieceLikes: json['Piece_likes'] ?? 0,
      pieceLocation: json['Piece_location'],
      pieceDescription: json['Piece_description'],
      pieceCreationDate: json['Piece_creation_date'] != null
          ? DateTime.parse(json['Piece_creation_date'])
          : DateTime.now(),
      pieceDisplay: json['Piece_display'],
      pieceForSale: json['Piece_for_sale'] ?? false,
      piecePrice: (json['Piece_price'] ?? 0).toDouble(),
    );
  }
}
