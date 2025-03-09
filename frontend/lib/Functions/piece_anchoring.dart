  import 'dart:convert';
  import 'package:flutter/material.dart';
  import 'package:http/http.dart' as http;
  import 'package:frames_app/Screens/home_screen.dart';

Future<Map<String, dynamic>> createNewAnchor(String unityData, String pieceData, String username) async {
  // Parse both JSON strings
  final unityJson = jsonDecode(unityData);
  final pieceJson = jsonDecode(pieceData);

  // Create AR position and rotation maps
  final arPosition = {
    'x': unityJson['arPosition']['x'],
    'y': unityJson['arPosition']['y'],
    'z': unityJson['arPosition']['z']
  };

  final arRotation = {
    'x': unityJson['arRotation']['x'],
    'y': unityJson['arRotation']['y'],
    'z': unityJson['arRotation']['z'],
    'w': unityJson['arRotation']['w']
  };

  // Add localScale
  final localScale = {
    'x': unityJson['localScale']['x'],
    'y': unityJson['localScale']['y'],
    'z': unityJson['localScale']['z']
  };

  // Combine data from both sources into new anchor object
  final newAnchor = {
    'anchorId': unityJson['anchorId'],
    'pieceId': pieceJson['PieceID'],
    'piece_owner': username,
    'frameName': pieceJson['frameName'],
    'faceName': pieceJson['faceName'],
    'imageUrl': pieceJson['imageUrl'],
    'latitude': unityJson['latitude'],
    'longitude': unityJson['longitude'],
    'arPosition': arPosition,
    'arRotation': arRotation,
    'localScale': localScale,                          // Add this
    'heightAboveCamera': unityJson['heightAboveCamera']  // Add this
  };

  return newAnchor;
}

Future<void> sendAnchorToServer(Map<String, dynamic> anchorData) async {
  final url = Uri.parse('https://x-fabric-419423.uc.r.appspot.com/anchor');
  
  try {
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(anchorData),
    );

    if (response.statusCode == 201) {
      print('Anchor saved successfully');
      final responseData = jsonDecode(response.body);
      print('Server response: ${responseData['message']}');
    } else {
      throw Exception('Failed to save anchor: ${response.statusCode}');
    }
  } catch (e) {
    print('Error sending anchor data: $e');
    throw Exception('Network error: $e');
  }
}


// Usage:
// final anchorMap = await createNewAnchor(jsonData, pieceData);
// await sendAnchorToServer(anchorMap);