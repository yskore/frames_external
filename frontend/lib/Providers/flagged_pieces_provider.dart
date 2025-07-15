import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frames_app/core/mixins/loading_mixin.dart';
import 'package:frames_app/core/mixins/message_mixin.dart';
import 'package:frames_app/core/repositories/piece_repository.dart';
import 'package:frames_app/models/flagged_piece_model.dart';

final flaggedPiecesProvider =
    StateNotifierProvider<FlaggedPiecesNotifier, List<FlaggedPiece>>((ref) {
  final pieceRepository = ref.read(pieceRepositoryProvider);

  return FlaggedPiecesNotifier(pieceRepository);
});

final flaggedPiecesLoadingProvider = StateProvider<bool>((ref) => false);

class FlaggedPiecesNotifier extends StateNotifier<List<FlaggedPiece>>
    with MessageMixin, LoadingMixin {
  final PieceRepository _pieceRepository;

  FlaggedPiecesNotifier(
    this._pieceRepository,
  ) : super([]);

  Future<void> loadMyFlaggedPieces() async {
    try {
      setLoading(true);
      clearError();

      final response = await _pieceRepository.getMyFlaggedPieces();

      if (response.isSuccess && response.data != null) {
        final List<dynamic> flaggedPiecesJson =
            response.data!['flaggedPieces'] ?? [];
        print('Flagged pieces JSON: $flaggedPiecesJson');
        final flaggedPieces = flaggedPiecesJson
            .map((json) => FlaggedPiece.fromJson(json))
            .toList();

        print('Parsed flagged pieces: $flaggedPieces');
        state = flaggedPieces;
      } else {
        showError(response.message ?? 'Failed to load flagged pieces');
      }
    } catch (e) {
      showError('Error loading flagged pieces: $e');
    } finally {
      setLoading(false);
    }
  }

  Future<bool> acceptFlag(String flagId) async {
    try {
      setLoading(true);
      clearError();

      final response = await _pieceRepository.respondToFlag(
        flagId: flagId,
        action: 'accept',
      );

      if (response.isSuccess) {
        // Remove the flagged piece from the list
        state = state.where((piece) => piece.pieceId != flagId).toList();
        return true;
      } else {
        showError(response.message ?? 'Failed to accept flag');
        return false;
      }
    } catch (e) {
      showError('Error accepting flag: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> disputeFlag(String flagId, String evidence, String comments,
      {String? filePath}) async {
    try {
      setLoading(true);
      clearError();

      final response = await _pieceRepository.respondToFlag(
        flagId: flagId,
        action: 'dispute',
        evidence: evidence.isNotEmpty ? evidence : null,
        comments: comments.isNotEmpty ? comments : null,
        filePath: filePath,
      );

      if (response.isSuccess) {
        // Remove the flagged piece from the list since it's now under dispute
        state = state.where((piece) => piece.pieceId != flagId).toList();
        return true;
      } else {
        showError(response.message ?? 'Failed to dispute flag');
        return false;
      }
    } catch (e) {
      showError('Error disputing flag: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> acknowledgeDisputeResolution(String pieceId) async {
    try {
      setLoading(true);
      clearError();

      final response =
          await _pieceRepository.acknowledgeDisputeResolution(pieceId);

      if (response.isSuccess) {
        // Remove the piece from the list since it's now acknowledged
        state = state.where((piece) => piece.pieceId != pieceId).toList();
        return true;
      } else {
        showError(
            response.message ?? 'Failed to acknowledge dispute resolution');
        return false;
      }
    } catch (e) {
      showError('Error acknowledging dispute resolution: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }
}
