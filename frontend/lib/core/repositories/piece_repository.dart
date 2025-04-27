import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frames_app/models/anchor_model.dart';
import 'package:uuid/uuid.dart';

import '../network/api_response.dart';
import '../network/api_service.dart';

final pieceRepositoryProvider = Provider<PieceRepository>((ref) {
  return PieceRepository();
});

class PieceRepository {
  final ApiService _apiService = ApiService();

  Future<ApiResponse> updatePieceInfo({
    required String pieceOwner,
    required String oldPieceTitle,
    required String newPieceTitle,
    required String pieceDescription,
    required bool pieceForSale,
    required double piecePrice,
    required String ownership, // Added ownership parameter

  }) async {
    try {
      final response = await _apiService.put(
        'update_piece',
        data: {
          'piece_owner': pieceOwner,
          'old_piece_title': oldPieceTitle,
          'new_piece_title': newPieceTitle,
          'updated_piece_description': pieceDescription,
          'piece_for_sale': pieceForSale,
          'piece_price': piecePrice,
          'ownership': ownership, // Added ownership to request body

        },
      );

      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Update piece error: $e');
      }
      return ApiResponse.error('Failed to update piece: $e');
    }
  }

  Future<ApiResponse> toggleLiveStatus(String pieceId, bool liveStatus) async {
    try {
      final response = await _apiService.post(
        'toggle_live_status',
        data: {
          'piece_id': pieceId,
          'live_status': liveStatus,
        },
      );

      if (kDebugMode) {
        if (response.isSuccess) {
          print('Piece live status updated successfully.');
          if (response.data != null && response.data!['message'] != null) {
            print('Server response: ${response.data!['message']}');
          }
        } else {
          print('Failed to update piece live status: ${response.message}');
        }
      }

      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Toggle live status error: $e');
      }
      return ApiResponse.error('Failed to update live status: $e');
    }
  }

  // This method provides a simpler interface for consumers
  Future<ApiResponse> togglePieceLiveStatus(
      String pieceId, bool liveStatus) async {
    try {
      final response = await toggleLiveStatus(pieceId, liveStatus);
      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Error toggling piece live status: $e');
      }
      return ApiResponse.error('Failed to toggle piece status: $e');
    }
  }

  Future<ApiResponse> deletePiece(String pieceTitle, String pieceOwner) async {
    try {
      final response = await _apiService.post(
        'delete_piece',
        data: {
          'piece_title': pieceTitle,
          'piece_owner': pieceOwner,
        },
      );

      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Delete piece error: $e');
      }
      return ApiResponse.error('Failed to delete piece: $e');
    }
  }

  Future<({String? error, AnchorModel? data})> getAnchorByPieceId(
      String pieceId) async {
    try {
      final response = await _apiService.post(
        'get_anchor_by_piece_id',
        data: {'pieceId': pieceId},
      );

      if (response.isSuccess && response.data != null) {
        return (error: null, data: AnchorModel.fromJson(response.data!));
      }
      return (error: response.message ?? "", data: null);
    } catch (e) {
      if (kDebugMode) {
        print('Get anchor by piece ID error: $e');
      }
      return (error: e.toString(), data: null);
    }
  }

  Future<ApiResponse> createPiece({
    required String pieceObject,
    required String pieceOwner,
    required String pieceTitle,
    required String frameName,
    required bool liveStatus,
    required int pieceLikes,
    required int pieceImpressions,
    required String pieceLocation,
    required String pieceDescription,
    required String pieceCreationDate,
    required String pieceDisplay,
    required bool pieceForSale,
    required double piecePrice,
    required String ownership,

  }) async {
    try {
      const uuid = Uuid();
      final pieceId = uuid.v4();

      final response = await _apiService.post(
        'new_piece',
        data: {
          'Piece_id': pieceId,
          'Piece_Object': pieceObject,
          'Piece_owner': pieceOwner,
          'Piece_title': pieceTitle,
          'Frame_name': frameName,
          'live_status': liveStatus.toString(),
          'piece_likes': pieceLikes.toString(),
          'piece_impressions': pieceImpressions.toString(),
          'Piece_location': pieceLocation,
          'Piece_description': pieceDescription,
          'Piece_creation_date': pieceCreationDate,
          'Piece_display': pieceDisplay.toString(),
          'Piece_for_sale': pieceForSale.toString(),
          'Piece_price': piecePrice.toString(),
          'ownership': ownership,

        },
      );

      if (kDebugMode) {
        if (response.isSuccess) {
          print('Piece created successfully with ID: $pieceId');
        } else {
          print('Failed to create piece: ${response.message}');
        }
      }

      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Create piece error: $e');
      }
      return ApiResponse.error('Failed to create piece: $e');
    }
  }

  Future<ApiResponse> fetchFrames() async {
    try {
      final response = await _apiService.get('frames');

      if (response.isSuccess && response.data != null) {
        if (kDebugMode) {
          print('Frames fetched successfully.');
        }
      }

      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Fetch frames error: $e');
      }
      return ApiResponse.error('Failed to fetch frames: $e');
    }
  }

Future<ApiResponse> getPieceById(String pieceId) async {
  try {
    final response = await _apiService.get(
      'piece/$pieceId',
    );
    if (kDebugMode) {
      if (response.isSuccess) {
        print('TEST: Piece details fetched successfully');
        print('TEST:Response data: ${response.data}');  // Add this line
      } else {
        print('Failed to fetch piece details: ${response.message}');
      }
    }
    return response;
  } catch (e) {
    if (kDebugMode) {
      print('TEST: Get piece by ID error: $e');
    }
    return ApiResponse.error('Failed to get piece details: $e');
  }
}

Future<ApiResponse> incrementImpressions(String pieceId) async {
  try {
    final response = await _apiService.post(
      'increment_impressions',
      data: {
        'pieceId': pieceId,
      },
    );

    if (kDebugMode) {
      if (response.isSuccess) {
        print('Piece impressions incremented successfully.');
      } else {
        print('Failed to increment impressions: ${response.message}');
      }
    }

    return response;
  } catch (e) {
    if (kDebugMode) {
      print('Increment impressions error: $e');
    }
    return ApiResponse.error('Failed to increment impressions: $e');
  }
}

Future<int> getPieceImpressions(String pieceId) async {
  try {
    final response = await _apiService.get(
      'piece_impressions/$pieceId',
    );

    if (response.isSuccess && response.data != null) {
      if (kDebugMode) {
        print('[IMP] Impressions response data: ${response.data}');
      }
      
      // Check for multiple possible response formats
      if (response.data!.containsKey('impressions')) {
        // Directly available in response data
        return response.data!['impressions'] as int;
      } else if (response.data!.containsKey('data') && 
                response.data!['data'] is Map<String, dynamic> &&
                response.data!['data'].containsKey('impressions')) {
        // Nested in 'data' object
        return response.data!['data']['impressions'] as int;
      } else {
        if (kDebugMode) {
          print('[IMP] Impressions data not found in response: ${response.data}');
        }
      }
    } else {
      if (kDebugMode) {
        print('[IMP] Failed to fetch impressions: ${response.message}');
      }
    }
    
    return 0; // Default if we can't get the data
  } catch (e) {
    if (kDebugMode) {
      print('[IMP] Error fetching piece impressions: $e');
    }
    return 0;
  }
}

}
