import 'dart:io';

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
    required String ownership,
    String? paymentDetails,
    String? currency,
    // NEW HIDDEN FEATURE PARAMETERS
    bool? isHidden,
    int? showRadius,
  }) async {
    try {
      final Map<String, dynamic> requestData = {
        'piece_owner': pieceOwner,
        'old_piece_title': oldPieceTitle,
        'new_piece_title': newPieceTitle,
        'updated_piece_description': pieceDescription,
        'piece_for_sale': pieceForSale,
        'piece_price': piecePrice,
        'ownership': ownership,
      };

      // Only add payment details if it's provided (not null or empty)
      if (paymentDetails != null && paymentDetails.isNotEmpty) {
        requestData['payment_details'] = paymentDetails;
      }

      // Add currency if provided
      if (currency != null && currency.isNotEmpty) {
        requestData['currency'] = currency;
      }

      // Add hidden feature fields if provided
      if (isHidden != null) {
        requestData['isHidden'] = isHidden;
      }

      if (showRadius != null) {
        requestData['showRadius'] = showRadius;
      }

      final response = await _apiService.put(
        'update_piece',
        data: requestData,
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
        // Extract the anchor data from the nested structure
        if (response.data!.containsKey('anchor')) {
          // The actual anchor data is inside the 'anchor' field
          return (
            error: null,
            data: AnchorModel.fromJson(response.data!['anchor'])
          );
        } else {
          print('Unexpected response structure: ${response.data}');
          return (error: "Unexpected response structure", data: null);
        }
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
    String? paymentDetails,
    required String ownership,
    String? currency,
    // NEW HIDDEN FEATURE PARAMETERS
    bool isHidden = false,
    int showRadius = 0,
  }) async {
    try {
      const uuid = Uuid();
      final pieceId = uuid.v4();

      final Map<String, dynamic> requestData = {
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
        // Hidden feature fields
        'isHidden': isHidden,
        'showRadius': showRadius,
      };

      // Add payment details if provided
      if (paymentDetails != null && paymentDetails.isNotEmpty) {
        requestData['payment_details'] = paymentDetails;
      }

      if (currency != null && currency.isNotEmpty) {
        requestData['currency'] = currency;
      } else {
        // Default to USD if not specified
        requestData['currency'] = 'USD';
      }

      final response = await _apiService.post(
        'new_piece',
        data: requestData,
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
          print('TEST:Response data: ${response.data}'); // Add this line
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
        'increment_impression',
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
            print(
                '[IMP] Impressions data not found in response: ${response.data}');
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

  Future<ApiResponse> searchPieces(String query) async {
    try {
      final response = await _apiService.post(
        'search_pieces',
        data: {'query': query},
      );

      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Search pieces error: $e');
      }
      return ApiResponse.error('Failed to search pieces: $e');
    }
  }

  Future<ApiResponse> flagPiece({
    required String pieceId,
    required String flagType,
  }) async {
    try {
      final response = await _apiService.post(
        '$pieceId/flag',
        data: {
          'flagType': flagType,
        },
      );

      if (kDebugMode) {
        if (response.isSuccess) {
          print('Piece flagged successfully: $pieceId with type: $flagType');
        } else {
          print('Failed to flag piece: ${response.message}');
        }
      }

      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Flag piece error: $e');
      }
      return ApiResponse.error('Failed to flag piece: $e');
    }
  }

  Future<ApiResponse> getMyFlaggedPieces() async {
    try {
      final response = await _apiService.get('flagged');

      if (kDebugMode) {
        if (response.isSuccess) {
          print('My flagged pieces fetched successfully');
        } else {
          print('Failed to fetch flagged pieces: ${response.message}');
        }
      }

      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Get my flagged pieces error: $e');
      }
      return ApiResponse.error('Failed to get flagged pieces: $e');
    }
  }

  Future<ApiResponse> respondToFlag({
    required String flagId,
    required String action,
    String? evidence,
    String? comments,
    String? filePath, // Add file path parameter
  }) async {
    try {
      // If we have a file to upload, use multipart form data
      if (filePath != null && filePath.isNotEmpty) {
        final response = await _apiService.postMultipart(
          '$flagId/flag-response',
          files: {'image': File(filePath)},
          data: {
            'action': action,
            if (comments != null) 'comments': comments,
          },
        );

        if (kDebugMode) {
          if (response.isSuccess) {
            print('Flag response with file submitted successfully: $action');
          } else {
            print('Failed to respond to flag with file: ${response.message}');
          }
        }

        return response;
      } else {
        // No file, use regular JSON request
        final Map<String, dynamic> requestData = {
          'action': action,
        };

        if (evidence != null) {
          requestData['evidence'] = evidence;
        }

        if (comments != null) {
          requestData['comments'] = comments;
        }

        final response = await _apiService.post(
          '$flagId/flag-response',
          data: requestData,
        );

        if (kDebugMode) {
          if (response.isSuccess) {
            print('Flag response submitted successfully: $action');
          } else {
            print('Failed to respond to flag: ${response.message}');
          }
        }

        return response;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Respond to flag error: $e');
      }
      return ApiResponse.error('Failed to respond to flag: $e');
    }
  }

//TODO:redundant method, remove later
  Future<ApiResponse> getPieceFlags(String pieceId) async {
    try {
      final response = await _apiService.get('piece-flags/$pieceId');

      if (kDebugMode) {
        if (response.isSuccess) {
          print('Piece flags fetched successfully');
        } else {
          print('Failed to fetch piece flags: ${response.message}');
        }
      }

      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Get piece flags error: $e');
      }
      return ApiResponse.error('Failed to get piece flags: $e');
    }
  }

  Future<ApiResponse> acknowledgeDisputeResolution(String pieceId) async {
    try {
      final response = await _apiService.post(
        '$pieceId/acknowledge-dispute',
        data: {},
      );

      if (kDebugMode) {
        if (response.isSuccess) {
          print('Dispute resolution acknowledged successfully');
        } else {
          print(
              'Failed to acknowledge dispute resolution: ${response.message}');
        }
      }

      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Acknowledge dispute resolution error: $e');
      }
      return ApiResponse.error('Failed to acknowledge dispute resolution: $e');
    }
  }
}
