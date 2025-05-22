import 'package:flutter/foundation.dart';
import 'package:frames_app/core/network/api_response.dart';
import 'package:frames_app/core/network/api_service.dart';
import 'package:frames_app/models/feed_entry_model.dart';

class FeedRepository {
  final ApiService _apiService = ApiService();

  Future<List<FeedEntry>> getFeed({int offset = 0, int limit = 20}) async {
    try {
      final response = await _apiService.get(
        'feed',
        queryParameters: {
          'offset': offset,
          'limit': limit,
        },
      );

      if (response.success && response.data != null) {
        final feedData = response.data!['feed'] as List<dynamic>;
        return feedData.map((json) => FeedEntry.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching feed: $e');
      }
      return [];
    }
  }

  Future<ApiResponse> markAsRead(List<String> entryIds) async {
    try {
      return await _apiService.post(
        'feed/mark-read',
        data: {'entryIds': entryIds},
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error marking feed entries as read: $e');
      }
      return ApiResponse.error('Failed to mark feed entries as read: $e');
    }
  }

  Future<ApiResponse> markAllAsRead() async {
    try {
      return await _apiService.post('feed/mark-all-read');
    } catch (e) {
      if (kDebugMode) {
        print('Error marking all feed entries as read: $e');
      }
      return ApiResponse.error('Failed to mark all feed entries as read: $e');
    }
  }

  Future<ApiResponse> deleteFeedEntry(String entryId) async {
    try {
      return await _apiService.delete('feed/$entryId');
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting feed entry: $e');
      }
      return ApiResponse.error('Failed to delete feed entry: $e');
    }
  }
}
