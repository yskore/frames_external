class Frame {
  final String id;
  final String frameObject;
  final String frameOwner;
  final String frameDisplay;
  final List<String> frameCollaborators;
  final String frameTitle;
  final String frameDescription;
  final DateTime frameCreationDate;
  final bool frameForSale;
  final double framePrice;
  final int v;
  final String faceName;

  Frame({
    required this.id,
    required this.frameObject,
    required this.frameOwner,
    required this.frameDisplay,
    required this.frameCollaborators,
    required this.frameTitle,
    required this.frameDescription,
    required this.frameCreationDate,
    required this.frameForSale,
    required this.framePrice,
    required this.v,
    required this.faceName,
  });

  factory Frame.fromJson(Map<String, dynamic> json) {
    return Frame(
      id: json['_id'] ?? '',
      frameObject: json['Frame_object'] ?? '',
      frameOwner: json['Frame_owner'] ?? '',
      frameDisplay: json['Frame_display'] ?? '',
      frameCollaborators: List<String>.from(json['Frame_collaborators'] ?? []),
      frameTitle: json['Frame_title'] ?? '',
      frameDescription: json['Frame_description'] ?? '',
      frameCreationDate: json['Frame_creation_date'] != null
          ? DateTime.parse(json['Frame_creation_date'])
          : DateTime.now(),
      frameForSale: json['Frame_for_sale'] ?? false,
      framePrice: (json['Frame_price'] ?? 0).toDouble(),
      v: json['__v'] ?? 0,
      faceName: json['Face_name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'Frame_object': frameObject,
      'Frame_owner': frameOwner,
      'Frame_display': frameDisplay,
      'Frame_collaborators': frameCollaborators,
      'Frame_title': frameTitle,
      'Frame_description': frameDescription,
      'Frame_creation_date': frameCreationDate.toIso8601String(),
      'Frame_for_sale': frameForSale,
      'Frame_price': framePrice,
      '__v': v,
      'Face_name': faceName,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Frame && other.id == id && other.frameTitle == frameTitle;
  }

  @override
  int get hashCode => id.hashCode ^ frameTitle.hashCode;

  Frame copyWith({
    String? id,
    String? frameObject,
    String? frameOwner,
    String? frameDisplay,
    List<String>? frameCollaborators,
    String? frameTitle,
    String? frameDescription,
    DateTime? frameCreationDate,
    bool? frameForSale,
    double? framePrice,
    int? v,
    String? faceName,
  }) {
    return Frame(
      id: id ?? this.id,
      frameObject: frameObject ?? this.frameObject,
      frameOwner: frameOwner ?? this.frameOwner,
      frameDisplay: frameDisplay ?? this.frameDisplay,
      frameCollaborators: frameCollaborators ?? this.frameCollaborators,
      frameTitle: frameTitle ?? this.frameTitle,
      frameDescription: frameDescription ?? this.frameDescription,
      frameCreationDate: frameCreationDate ?? this.frameCreationDate,
      frameForSale: frameForSale ?? this.frameForSale,
      framePrice: framePrice ?? this.framePrice,
      v: v ?? this.v,
      faceName: faceName ?? this.faceName,
    );
  }

  @override
  String toString() {
    return 'Frame(id: $id, title: $frameTitle)';
  }
}
