import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frames_app/core/mixins/loading_mixin.dart';
import 'package:frames_app/core/mixins/message_mixin.dart';
import 'package:frames_app/core/repositories/feed_repository.dart';
import 'package:frames_app/models/feed_entry_model.dart';

final feedRepositoryProvider = Provider<FeedRepository>((ref) {
  return FeedRepository();
});

final feedProvider =
    StateNotifierProvider<FeedNotifier, List<FeedEntry>>((ref) {
  final feedRepository = ref.read(feedRepositoryProvider);

  return FeedNotifier(feedRepository);
});

final unreadFeedCountProvider = Provider<int>((ref) {
  final feedEntries = ref.watch(feedProvider);
  return feedEntries.where((entry) => !entry.read).length;
});

class FeedNotifier extends StateNotifier<List<FeedEntry>>
    with LoadingMixin, MessageMixin {
  final FeedRepository _feedRepository;

  bool _isLoading = false;
  int _currentOffset = 0;
  final int _limit = 20;
  bool _hasMore = true;
  bool _isInitialized = false;

  FeedNotifier(this._feedRepository) : super([]);

  bool get isInitialized => _isInitialized;

  Future<void> loadFeed({bool refresh = false}) async {
    if (_isLoading) return;

    try {
      _isLoading = true;
      if (refresh) {
        setLoading(true);
        _currentOffset = 0;
        _hasMore = true;
      }

      if (!_hasMore && !refresh) return;

      final feedEntries = await _feedRepository.getFeed(
        offset: _currentOffset,
        limit: _limit,
      );

      if (feedEntries.isEmpty) {
        _hasMore = false;
      } else {
        _currentOffset += feedEntries.length;

        if (refresh) {
          state = feedEntries;
        } else {
          state = [...state, ...feedEntries];
        }
      }

      _isInitialized = true;
    } catch (e) {
      showError('Failed to load feed: $e');
    } finally {
      _isLoading = false;
      setLoading(false);
    }
  }

  Future<void> markAsRead(String entryId) async {
    try {
      final response = await _feedRepository.markAsRead([entryId]);

      if (response.success) {
        state = [
          for (final entry in state)
            if (entry.id == entryId) entry.copyWith(read: true) else entry,
        ];
      } else {
        showError(response.message ?? 'Failed to mark as read');
      }
    } catch (e) {
      showError('Error marking as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      setLoading(true);

      final response = await _feedRepository.markAllAsRead();

      if (response.success) {
        state = state.map((entry) => entry.copyWith(read: true)).toList();
      } else {
        showError(response.message ?? 'Failed to mark all as read');
      }
    } catch (e) {
      showError('Error marking all as read: $e');
    } finally {
      setLoading(false);
    }
  }

  Future<void> deleteFeedEntry(String entryId) async {
    try {
      final response = await _feedRepository.deleteFeedEntry(entryId);

      if (response.success) {
        state = state.where((entry) => entry.id != entryId).toList();
      } else {
        showError(response.message ?? 'Failed to delete feed entry');
      }
    } catch (e) {
      showError('Error deleting feed entry: $e');
    }
  }

  void clearFeed() {
    state = [];
    _isInitialized = false;
    _currentOffset = 0;
    _hasMore = true;
    _isLoading = false;
  }
}
