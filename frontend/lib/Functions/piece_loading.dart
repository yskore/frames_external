import 'dart:convert';

// import 'package:flutter_unity_widget/flutter_unity_widget.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

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

class LocationService {
  Future<Position?> getCurrentLocation() async {
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }
}

void validateAnchorData(Anchor anchor) {
  print('Validating anchor data:');
  print(
      'Scale - x: ${anchor.localScale.x}, y: ${anchor.localScale.y}, z: ${anchor.localScale.z}');
  print('Height above camera: ${anchor.heightAboveCamera}');

  if (anchor.localScale.x == 0 ||
      anchor.localScale.y == 0 ||
      anchor.localScale.z == 0) {
    print('Warning: Scale contains zero values');
  }

  if (anchor.heightAboveCamera == 0) {
    print('Warning: Height above camera is zero');
  }
}

class Anchor {
  final String anchorId;
  final String? pieceOwner;
  final String pieceId;
  final String frameName;
  final String faceName;
  final String imageUrl;
  final Location location;
  final Vector3 arPosition;
  final Quaternion arRotation;
  // Add these new fields:
  final Vector3 localScale;
  final double heightAboveCamera;

  Anchor({
    required this.anchorId,
    this.pieceOwner,
    required this.pieceId,
    required this.frameName,
    required this.faceName,
    required this.imageUrl,
    required this.location,
    required this.arPosition,
    required this.arRotation,
    required this.localScale, // Add this
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
        'localScale': localScale.toJson(), // Add this
        'heightAboveCamera': heightAboveCamera,
      };

  factory Anchor.fromJson(Map<String, dynamic> json) => Anchor(
        anchorId: json['anchorId'],
        pieceOwner: json['pieceOwner'],
        pieceId: json['pieceId'],
        frameName: json['frameName'],
        faceName: json['faceName'],
        imageUrl: json['imageUrl'],
        location: Location.fromJson(json['location']),
        arPosition: Vector3.fromJson(json['arPosition']),
        arRotation: Quaternion.fromJson(json['arRotation']),
        localScale: Vector3.fromJson(json['localScale']), // Add this
        heightAboveCamera: json['heightAboveCamera'].toDouble(), // Add this
      );
}

// Functions

class AnchorService {
  Future<List<Anchor>> fetchNearbyAnchors(
      double latitude, double longitude, double radius) async {
    try {
      final response = await http.post(
        Uri.parse('https://x-fabric-419423.uc.r.appspot.com/fetchanchors'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'latitude': latitude,
          'longitude': longitude,
          'radius': radius,
        }),
      );

      if (response.statusCode == 200) {
        final List<dynamic> anchorsJson = jsonDecode(response.body)['anchors'];
        print(
            'Fetched anchors: ${jsonEncode(anchorsJson)}'); // Prints full JSON

        return anchorsJson.map((json) => Anchor.fromJson(json)).toList();
      } else {
        throw Exception('Failed to fetch anchors: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching anchors: $e');
      rethrow;
    }
  }

//     Future<void> sendAnchorsToUnity(UnityWidgetController controller, List<Anchor> anchors) async {
//   try {
//     print('SENDING ANCHORS TO UNITY');

//     // Add debug messages here, before creating the data map
//     for (var anchor in anchors) {
//       print('Anchor data being sent to Unity:');
//       print('Anchor ID: ${anchor.anchorId}');
//       print('Scale: ${anchor.localScale.toJson()}');
//       print('Height above camera: ${anchor.heightAboveCamera}');
//     }

//     final data = {
//       'pieces': anchors.map((anchor) => {
//         'anchorId': anchor.anchorId,
//         'frameName': anchor.frameName,
//         'faceName': anchor.faceName,
//         'imageUrl': anchor.imageUrl,
//         'latitude': anchor.location.coordinates[1],
//         'longitude': anchor.location.coordinates[0],
//         'arPosition': anchor.arPosition.toJson(),
//         'arRotation': anchor.arRotation.toJson(),
//         'localScale': anchor.localScale.toJson(),
//         'heightAboveCamera': anchor.heightAboveCamera,
//       }).toList(),
//     };

//     await controller.postMessage(
//       'LoadExistingPieces',
//       'LoadNearbyPieces',
//       jsonEncode(data),
//     );
//   } catch (e) {
//     print('Error sending anchors to Unity: $e');
//     rethrow;
//   }
// }
}
