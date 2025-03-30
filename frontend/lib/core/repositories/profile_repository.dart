import 'package:flutter/foundation.dart';

import '../network/api_response.dart';
import '../network/api_service.dart';

class ProfileRepository {
  final ApiService _apiService = ApiService();

  Future<ApiResponse> getUserProfile(String username) async {
    try {
      final response = await _apiService.post(
        'getProfile',
        data: {'username': username},
      );

      if (response.isSuccess && response.data != null) {
        return response;
      }
      return ApiResponse.error(
          response.message ?? 'Failed to get user profile');
    } catch (e) {
      if (kDebugMode) {
        print('Get user profile error: $e');
      }
      return ApiResponse.error('Failed to get user profile: $e');
    }
  }

  Future<ApiResponse> getFollowerCount(String username) async {
    try {
      final response = await _apiService.post(
        'getfollowercount',
        data: {'username': username},
      );

      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Get follower count error: $e');
      }
      return ApiResponse.error('Failed to get follower count: $e');
    }
  }

  Future<ApiResponse> getFollowingCount(String username) async {
    try {
      final response = await _apiService.post(
        'getfollowingcount',
        data: {'username': username},
      );

      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Get following count error: $e');
      }
      return ApiResponse.error('Failed to get following count: $e');
    }
  }

  Future<ApiResponse> getAnchorsByOwner(String username) async {
    try {
      final response = await _apiService.post(
        'get_anchors_by_owner',
        data: {'username': username},
      );

      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Get anchors error: $e');
      }
      return ApiResponse.error('Failed to get anchors: $e');
    }
  }

  Future<ApiResponse> getPieceCount(String username) async {
    try {
      final response = await _apiService.post(
        'getPieceCount',
        data: {'username': username},
      );

      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Get piece count error: $e');
      }
      return ApiResponse.error('Failed to get piece count: $e');
    }
  }

  Future<ApiResponse> getPiecesByOwner(String username) async {
    try {
      final response = await _apiService.post(
        'getpiecesbyowner',
        data: {'username': username},
      );

      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Get pieces by owner error: $e');
      }
      return ApiResponse.error('Failed to get pieces by owner: $e');
    }
  }

  Future<ApiResponse> createUserProfile(String username) async {
    try {
      final response = await _apiService.post(
        'set_profile',
        data: {'username': username},
      );

      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Create profile error: $e');
      }
      return ApiResponse.error('Failed to create user profile: $e');
    }
  }

  Future<ApiResponse> updateUserProfile(
      String username, String bio, String profilePictureUrl) async {
    try {
      final response = await _apiService.post(
        'update_profile',
        data: {
          'username': username,
          'Bio': bio,
          'imageUrl': profilePictureUrl,
        },
      );

      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Update profile error: $e');
      }
      return ApiResponse.error('Failed to update user profile: $e');
    }
  }
}
