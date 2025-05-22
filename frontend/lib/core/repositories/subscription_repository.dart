import 'package:flutter/foundation.dart';
import 'package:frames_app/core/network/api_response.dart';
import 'package:frames_app/core/network/api_service.dart';

class SubscriptionRepository {
  final ApiService _apiService = ApiService();

  /// Get subscriptions (users that the current user subscribes to)
  Future<ApiResponse> getMySubscriptions() async {
    try {
      final response = await _apiService.get('my-subscriptions');
      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting subscriptions: $e');
      }
      return ApiResponse.error('Failed to fetch subscriptions: $e');
    }
  }

  /// Get subscribers (users who subscribe to the current user)
  Future<ApiResponse> getMySubscribers() async {
    try {
      final response = await _apiService.get('my-subscribers');
      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting subscribers: $e');
      }
      return ApiResponse.error('Failed to fetch subscribers: $e');
    }
  }

  /// Subscribe to a user
  Future<ApiResponse> subscribeToUser(String targetUsername) async {
    try {
      final response = await _apiService.post(
        'subscribe',
        data: {'targetUsername': targetUsername},
      );
      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Error subscribing to user: $e');
      }
      return ApiResponse.error('Failed to subscribe to user: $e');
    }
  }

  /// Unsubscribe from a user
  Future<ApiResponse> unsubscribeFromUser(String targetUsername) async {
    try {
      final response = await _apiService.post(
        'unsubscribe',
        data: {'targetUsername': targetUsername},
      );
      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Error unsubscribing from user: $e');
      }
      return ApiResponse.error('Failed to unsubscribe from user: $e');
    }
  }

  Future<ApiResponse> isSubscribedToUser(String targetUsername) async {
    try {
      final response = await _apiService.post(
        'check-subscription',
        data: {'targetUsername': targetUsername},
      );
      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking subscription status: $e');
      }
      return ApiResponse.error('Failed to check subscription status: $e');
    }
  }

  /// Get subscribers of a specific user by username
  Future<ApiResponse> getSubscribersByUsername(String username) async {
    try {
      final response = await _apiService.get('subscribers/$username');
      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting subscribers for $username: $e');
      }
      return ApiResponse.error('Failed to fetch subscribers: $e');
    }
  }
}
