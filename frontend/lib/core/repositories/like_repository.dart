import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_response.dart';
import '../network/api_service.dart';

final likeRepositoryProvider = Provider<LikeRepository>((ref) {
  return LikeRepository();
});

class LikeRepository {
  final ApiService _apiService = ApiService();

  /// Toggle like status (like or unlike) for a piece
  Future<ApiResponse> toggleLike(String pieceId, String username) async {
    try {
      final response = await _apiService.post(
        'toggle_like',
        data: {
          'pieceId': pieceId,
          'username': username,
        },
      );

      if (kDebugMode) {
        if (response.isSuccess) {
          final isLiked = response.data?['isLiked'] ?? false;
          print('Piece ${isLiked ? 'liked' : 'unliked'} successfully');
        } else {
          print('Failed to toggle like: ${response.message}');
        }
      }

      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Toggle like error: $e');
      }
      return ApiResponse.error('Failed to toggle like status: $e');
    }
  }

  /// Check if a user has liked a specific piece
  Future<ApiResponse> checkLikeStatus(String pieceId, String username) async {
    try {
      final response = await _apiService.get(
        'check_like',
        queryParameters: {
          'pieceId': pieceId,
          'username': username,
        },
      );

      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Check like status error: $e');
      }
      return ApiResponse.error('Failed to check like status: $e');
    }
  }

  /// Get all pieces liked by a user
  Future<ApiResponse> getUserLikes(String username) async {
    try {
      final response = await _apiService.get(
        'user_likes/$username',
      );

      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Get user likes error: $e');
      }
      return ApiResponse.error('Failed to get user likes: $e');
    }
  }

  /// Get like count and recent likers for a piece
  Future<ApiResponse> getPieceLikes(String pieceId, {int limit = 5}) async {
    try {
      final response = await _apiService.get(
        'piece_likes/$pieceId',
        queryParameters: {
          'limit': limit.toString(),
        },
      );

      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Get piece likes error: $e');
      }
      return ApiResponse.error('Failed to get piece likes: $e');
    }
  }
}