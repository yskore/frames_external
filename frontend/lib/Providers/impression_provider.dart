import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frames_app/core/repositories/piece_repository.dart';
import 'package:frames_app/Providers/error_provider.dart';

// Provider to manage the impression count for each piece
final pieceImpressionCountProvider = StateProvider.family<int, String>((ref, pieceId) => 0);

// Provider for the impression notifier
final impressionNotifierProvider = Provider<ImpressionNotifier>((ref) {
  final pieceRepository = ref.read(pieceRepositoryProvider);
  final errorNotifier = ref.read(errorProvider.notifier);
  return ImpressionNotifier(ref, pieceRepository, errorNotifier);
});

class ImpressionNotifier {
  final Ref _ref;
  final PieceRepository _pieceRepository;
  final ErrorNotifier _errorNotifier;

  ImpressionNotifier(
    this._ref,
    this._pieceRepository,
    this._errorNotifier,
  );

  // Record a new impression for a piece
  Future<bool> recordImpression(String pieceId, {bool showLoading = true}) async {
    try {
      // Get current impression count
      final currentCount = _ref.read(pieceImpressionCountProvider(pieceId));
      
      // Update local state immediately for better UX
      _ref.read(pieceImpressionCountProvider(pieceId).notifier).state = currentCount + 1;
      
      // Call API to increment impression
      final response = await _pieceRepository.incrementImpressions(pieceId);
      
      if (response.isSuccess) {
        // Update the local state with the server return value if available
        if (response.data != null && response.data!.containsKey('impressions')) {
          final serverCount = response.data!['impressions'];
          if (serverCount != null) {
            _ref.read(pieceImpressionCountProvider(pieceId).notifier).state = serverCount;
          }
        }
        return true;
      } else {
        // Revert to previous count on error
        _ref.read(pieceImpressionCountProvider(pieceId).notifier).state = currentCount;
        if (kDebugMode) {
          print('Failed to record impression: ${response.message}');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error recording impression: $e');
      }
      return false;
    }
  }

  // Initialize impression count for a piece
  void setImpressionCount(String pieceId, int count) {
    _ref.read(pieceImpressionCountProvider(pieceId).notifier).state = count;
  }
}