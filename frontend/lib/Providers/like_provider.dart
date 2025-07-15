import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frames_app/core/mixins/loading_mixin.dart';
import 'package:frames_app/core/mixins/message_mixin.dart';
import 'package:frames_app/core/repositories/like_repository.dart';
import 'package:frames_app/providers/user_provider.dart';

/// Provider to track the like status of the current piece being viewed
final currentPieceLikeStatusProvider =
    StateProvider.family<bool, String>((ref, pieceId) => false);

/// Provider to track like counts for pieces
final pieceLikeCountProvider =
    StateProvider.family<int, String>((ref, pieceId) => 0);

/// Notifier for managing piece likes
final likeNotifierProvider = Provider<LikeNotifier>((ref) {
  final likeRepository = ref.read(likeRepositoryProvider);

  final userModel = ref.read(userProvider);

  return LikeNotifier(
    likeRepository,
    ref,
    userModel?.username ?? '',
  );
});

class LikeNotifier with MessageMixin, LoadingMixin {
  final LikeRepository _likeRepository;

  final Ref _ref;
  final String _username;

  LikeNotifier(
    this._likeRepository,
    this._ref,
    this._username,
  );

  /// Check if the current user has liked a piece
  Future<void> checkLikeStatus(String pieceId,
      {bool showLoading = false}) async {
    if (_username.isEmpty) return;

    try {
      if (showLoading) {
        setLoading(true);
      }

      final response =
          await _likeRepository.checkLikeStatus(pieceId, _username);

      if (response.isSuccess && response.data != null) {
        final isLiked = response.data!['isLiked'] ?? false;
        final likeCount = response.data!['likeCount'] ?? 0;

        // Update state
        _ref.read(currentPieceLikeStatusProvider(pieceId).notifier).state =
            isLiked;
        _ref.read(pieceLikeCountProvider(pieceId).notifier).state = likeCount;
      } else {
        showError(response.message);
      }
    } catch (e) {
      showError('Failed to check like status: $e');
    } finally {
      if (showLoading) {
        setLoading(false);
      }
    }
  }

  /// Toggle like status for a piece
  Future<bool> toggleLike(String pieceId, {bool showLoading = true}) async {
    if (_username.isEmpty) {
      showError('You must be logged in to like pieces');
      return false;
    }

    try {
      if (showLoading) {
        setLoading(true);
      }

      final response = await _likeRepository.toggleLike(pieceId, _username);

      if (response.isSuccess && response.data != null) {
        final isLiked = response.data!['isLiked'] ?? false;
        final likeCount = response.data!['likeCount'] ?? 0;

        // Update state
        _ref.read(currentPieceLikeStatusProvider(pieceId).notifier).state =
            isLiked;
        _ref.read(pieceLikeCountProvider(pieceId).notifier).state = likeCount;

        return true;
      } else {
        showError(response.message);
        return false;
      }
    } catch (e) {
      showError('Failed to toggle like: $e');
      return false;
    } finally {
      if (showLoading) {
        setLoading(false);
      }
    }
  }

  /// Get all pieces liked by the current user
  Future<List<String>?> getUserLikedPieceIds({bool showLoading = true}) async {
    if (_username.isEmpty) return [];

    try {
      if (showLoading) {
        setLoading(true);
      }

      final response = await _likeRepository.getUserLikes(_username);

      if (response.isSuccess &&
          response.data != null &&
          response.data!['likes'] != null) {
        final pieces = response.data!['likes'] as List<dynamic>;
        return pieces.map((piece) => piece['Piece_id'] as String).toList();
      } else {
        showError(response.message);
        return null;
      }
    } catch (e) {
      showError('Failed to get liked pieces: $e');
      return null;
    } finally {
      if (showLoading) {
        setLoading(false);
      }
    }
  }
}
