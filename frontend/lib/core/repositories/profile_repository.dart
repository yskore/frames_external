import 'package:flutter/foundation.dart';

import '../network/api_response.dart';
import '../network/api_service.dart';

class ProfileRepository {
  final ApiService _apiService = ApiService();

  Future<ApiResponse> getUserProfile(String username) async {
    try {
      final response = await _apiService.get(
        'profile',
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

  Future<ApiResponse> getPiecesByOwner(String username) async {
    try {
      final response = await _apiService.get(
        'pieces',
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
