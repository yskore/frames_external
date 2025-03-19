import 'package:flutter/material.dart';

class Location {
  final String type;
  final List<double> coordinates;

  Location({
    required this.type,
    required this.coordinates,
  });

  factory Location.fromJson(Map<String, dynamic> json) => Location(
        type: json['type'],
        coordinates: (json['coordinates'] as List)
            .map((coord) => coord is int ? coord.toDouble() : coord as double)
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'type': type,
        'coordinates': coordinates,
      };
}

// In piece_loading.dart, update the existing Vector3 class
class Vector3 {
  final double x, y, z;

  Vector3({required this.x, required this.y, required this.z});

  factory Vector3.fromJson(Map<String, dynamic> json) {
    if (json is List) {
      // Handle array format
      return Vector3(x: json[0], y: json[1], z: json[2]);
    }
    // Handle object format
    return Vector3(
      x: json['x'] is int ? (json['x'] as int).toDouble() : json['x'],
      y: json['y'] is int ? (json['y'] as int).toDouble() : json['y'],
      z: json['z'] is int ? (json['z'] as int).toDouble() : json['z'],
    );
  }

  Map<String, dynamic> toJson() => {'x': x, 'y': y, 'z': z};
}

class Quaternion {
  final double x, y, z, w;

  Quaternion(
      {required this.x, required this.y, required this.z, required this.w});

  factory Quaternion.fromJson(Map<String, dynamic> json) => Quaternion(
        x: json['x'] is int ? (json['x'] as int).toDouble() : json['x'],
        y: json['y'] is int ? (json['y'] as int).toDouble() : json['y'],
        z: json['z'] is int ? (json['z'] as int).toDouble() : json['z'],
        w: json['w'] is int ? (json['w'] as int).toDouble() : json['w'],
      );

  Map<String, dynamic> toJson() => {'x': x, 'y': y, 'z': z, 'w': w};
}

class AnchorModel {
  final String anchorId;
  final String? pieceOwner;
  final String pieceId;
  final String frameName;
  final String faceName;
  final String imageUrl;
  final Location location;
  final Vector3 arPosition;
  final Quaternion arRotation;
  final Vector3 localScale;
  final double heightAboveCamera;

  AnchorModel({
    required this.anchorId,
    this.pieceOwner,
    required this.pieceId,
    required this.frameName,
    required this.faceName,
    required this.imageUrl,
    required this.location,
    required this.arPosition,
    required this.arRotation,
    required this.localScale,
    required this.heightAboveCamera,
  });

  Map<String, dynamic> toJson() => {
        'anchorId': anchorId,
        'pieceOwner': pieceOwner,
        'pieceId': pieceId,
        'frameName': frameName,
        'faceName': faceName,
        'imageUrl': imageUrl,
        'location': location.toJson(),
        'arPosition': arPosition.toJson(),
        'arRotation': arRotation.toJson(),
        'localScale': localScale.toJson(),
        'heightAboveCamera': heightAboveCamera,
      };

  factory AnchorModel.fromJson(Map<String, dynamic> json) {
    return AnchorModel(
      anchorId: json['anchorId'],
      pieceOwner: json['pieceOwner'],
      pieceId: json['pieceId'],
      frameName: json['frameName'],
      faceName: json['faceName'],
      imageUrl: json['imageUrl'],
      location: Location.fromJson(json['location']),
      arPosition: Vector3.fromJson(json['arPosition']),
      arRotation: Quaternion.fromJson(json['arRotation']),
      localScale: Vector3.fromJson(json['localScale']),
      heightAboveCamera: json['heightAboveCamera'].toDouble(),
    );
  }
  void validateAnchorData() {
    // Using logger instead of print for production code
    debugPrint(
        'Scale - x: ${localScale.x}, y: ${localScale.y}, z: ${localScale.z}');
    debugPrint('Height above camera: $heightAboveCamera');

    if (localScale.x == 0 || localScale.y == 0 || localScale.z == 0) {
      debugPrint('Warning: Scale contains zero values');
    }

    if (heightAboveCamera == 0) {
      debugPrint('Warning: Height above camera is zero');
    }
  }

  // Convert from old Anchor class format
  // factory AnchorModel.fromAnchor(Anchor anchor) {
  //   return AnchorModel(
  //     anchorId: anchor.anchorId,
  //     pieceOwner: anchor.pieceOwner,
  //     pieceId: anchor.pieceId,
  //     frameName: anchor.frameName,
  //     faceName: anchor.faceName,
  //     imageUrl: anchor.imageUrl,
  //     location: anchor.location,
  //     arPosition: anchor.arPosition,
  //     arRotation: anchor.arRotation,
  //     localScale: anchor.localScale,
  //     heightAboveCamera: anchor.heightAboveCamera,
  //   );
  // }
}
