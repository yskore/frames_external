import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frames_app/core/services/location.dart';

import '../../models/anchor_model.dart';
import '../network/api_response.dart';
import '../network/api_service.dart';

final anchorRepositoryProvider = Provider<AnchorRepository>((ref) {
  return AnchorRepository();
});

class AnchorRepository {
  final ApiService _apiService = ApiService();

  Map<String, dynamic> _createAnchorData(
      String unityData, String pieceData, String username) {
    try {
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
  'localScale': localScale,
  'heightAboveCamera': unityJson['heightAboveCamera'],
  'cloudAnchorId': unityJson['cloudAnchorId'] ?? '' // Add this when available
};

  return newAnchor;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating anchor data: $e');
      }
      rethrow;
    }
  }

  Future<ApiResponse> saveAnchor(
      String unityData, String pieceData, String username) async {
    final anchorData = _createAnchorData(unityData, pieceData, username);
    try {
      final response = await _apiService.post(
        'anchor',
        data: anchorData,
      );

      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Error saving anchor: $e');
      }
      return ApiResponse.error('Failed to save anchor: $e');
    }
  }

  Future<({String? error, List<AnchorModel>? data})> fetchNearbyAnchors(
      radius) async {
    try {
      final location = await LocationService.getCurrentLocation();
      final response = await _apiService.post(
        'fetchanchors',
        data: {
          'latitude': location.latitude,
          'longitude': location.longitude,
          'radius': radius,
        },
      );

      if (response.isSuccess &&
          response.data != null &&
          response.data!['anchors'] != null) {
        final List<dynamic> anchorsJson = response.data!['anchors'];
        print('[LOGS] Cloud: anchorsJson: $anchorsJson');
        return (
          error: null,
          data: anchorsJson.map((json) => AnchorModel.fromJson(json)).toList()
        );
      }

      return (error: response.message, data: null);
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching nearby anchors: $e');
      }
      return (error: e.toString(), data: null);
    }
  }

  Future<ApiResponse> updateAnchor(
      String anchorId, Map<String, dynamic> updatedData) async {
    try {
      final response = await _apiService.put(
        'update_anchor',
        data: {
          'anchorId': anchorId,
          ...updatedData,
        },
      );

      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating anchor: $e');
      }
      return ApiResponse.error('Failed to update anchor: $e');
    }
  }

  Future<ApiResponse> deleteAnchor(String anchorId) async {
    try {
      final response = await _apiService.post(
        'delete_anchor',
        data: {'anchorId': anchorId},
      );

      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting anchor: $e');
      }
      return ApiResponse.error('Failed to delete anchor: $e');
    }
  }
}
