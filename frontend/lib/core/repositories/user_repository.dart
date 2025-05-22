import 'package:flutter/foundation.dart';

import '../auth/token_manager.dart';
import '../network/api_response.dart';
import '../network/api_service.dart';

class UserRepository {
  final ApiService _apiService = ApiService();
  final TokenManager _tokenManager = TokenManager();

  Future<ApiResponse> login(String username, String password,
      {String? pushToken}) async {
    try {
      final data = {
        'username': username,
        'password': password,
      };

      // Add push token if available
      if (pushToken != null && pushToken.isNotEmpty) {
        data['push_token'] = pushToken;
      }

      final response = await _apiService.post(
        'login',
        data: data,
      );

      if (response.isSuccess && response.data != null) {
        // Save token if available in response

        if (response.data!.containsKey('accessToken')) {
          await _tokenManager.saveToken(
              response.data!['accessToken'], username);
        }
      }

      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Login error: $e');
      }
      return ApiResponse.error('Failed to login: $e');
    }
  }

  Future<ApiResponse> signup(Map<String, dynamic> userData) async {
    try {
      final response = await _apiService.post(
        'user_basic',
        data: userData,
      );

      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Signup error: $e');
      }
      return ApiResponse.error('Failed to create account: $e');
    }
  }

  Future<ApiResponse> getUserProfile(String username) async {
    try {
      final response = await _apiService.get(
        'user_info',
        queryParameters: {'username': username},
      );

      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Get user profile error: $e');
      }
      return ApiResponse.error('Failed to get user profile: $e');
    }
  }

  Future<ApiResponse> userExists(String username, String email) async {
    try {
      final response = await _apiService.post(
        'user_exists',
        data: {
          'username': username,
          'email': email,
        },
      );

      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Check username exists error: $e');
      }
      return ApiResponse.error('Failed to check username: $e');
    }
  }

  Future<ApiResponse> sendOTP(String email) async {
    try {
      final response = await _apiService.post(
        'send-otp',
        data: {
          'email': email,
        },
      );

      if (kDebugMode) {
        print('Send OTP response: ${response.message}');
      }

      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Send OTP error: $e');
      }
      return ApiResponse.error('Failed to send verification code: $e');
    }
  }

  Future<ApiResponse> verifyOTP(String email, String otp) async {
    try {
      final response = await _apiService.post(
        'verify-otp',
        data: {
          'email': email,
          'otp': otp,
        },
      );

      if (kDebugMode) {
        print('Verify OTP response: ${response.message}');
      }

      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Verify OTP error: $e');
      }
      return ApiResponse.error('Failed to verify code: $e');
    }
  }

  Future<ApiResponse> updatePushToken(String pushToken) async {
    try {
      final response = await _apiService.post(
        'update-push-token',
        data: {
          'push_token': pushToken,
        },
      );

      return response;
    } catch (e) {
      return ApiResponse.error('Failed to update push token: $e');
    }
  }

  Future<ApiResponse> getProfileWithPieces(String username) async {
    try {
      final response = await _apiService.get(
        'profile_with_pieces/$username',
      );

      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Get profile with pieces error: $e');
      }
      return ApiResponse.error('Failed to get profile with pieces: $e');
    }
  }

  Future<ApiResponse> searchUsers(String query) async {
    try {
      final response = await _apiService.post(
        'search_users',
        data: {'query': query},
      );

      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Search users error: $e');
      }
      return ApiResponse.error('Failed to search users: $e');
    }
  }

  Future<void> logout() async {
    await _tokenManager.clearToken();
  }
}
