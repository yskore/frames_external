import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frames_app/Providers/error_provider.dart';
import 'package:frames_app/Providers/loading_provider.dart';
import 'package:frames_app/core/repositories/piece_repository.dart';
import 'package:frames_app/models/flagged_piece_model.dart';

final flaggedPiecesProvider =
    StateNotifierProvider<FlaggedPiecesNotifier, List<FlaggedPiece>>((ref) {
  final pieceRepository = ref.read(pieceRepositoryProvider);
  final errorNotifier = ref.read(errorProvider.notifier);
  final loadingNotifier = ref.read(loadingProvider.notifier);

  return FlaggedPiecesNotifier(pieceRepository, errorNotifier, loadingNotifier);
});

final flaggedPiecesLoadingProvider = StateProvider<bool>((ref) => false);

class FlaggedPiecesNotifier extends StateNotifier<List<FlaggedPiece>> {
  final PieceRepository _pieceRepository;
  final ErrorNotifier _errorNotifier;
  final LoadingNotifier _loadingNotifier;

  FlaggedPiecesNotifier(
    this._pieceRepository,
    this._errorNotifier,
    this._loadingNotifier,
  ) : super([]);

  Future<void> loadMyFlaggedPieces() async {
    try {
      _loadingNotifier.setLoading(true);
      _errorNotifier.clearError();

      final response = await _pieceRepository.getMyFlaggedPieces();

      if (response.isSuccess && response.data != null) {
        final List<dynamic> flaggedPiecesJson =
            response.data!['flaggedPieces'] ?? [];
        final flaggedPieces = flaggedPiecesJson
            .map((json) => FlaggedPiece.fromJson(json))
            .toList();

        state = flaggedPieces;
      } else {
        _errorNotifier
            .setError(response.message ?? 'Failed to load flagged pieces');
      }
    } catch (e) {
      _errorNotifier.setError('Error loading flagged pieces: $e');
    } finally {
      _loadingNotifier.setLoading(false);
    }
  }

  Future<bool> acceptFlag(String flagId) async {
    try {
      _loadingNotifier.setLoading(true);
      _errorNotifier.clearError();

      final response = await _pieceRepository.respondToFlag(
        flagId: flagId,
        action: 'accept',
      );

      if (response.isSuccess) {
        // Remove the flagged piece from the list
        state = state.where((piece) => piece.pieceId != flagId).toList();
        return true;
      } else {
        _errorNotifier.setError(response.message ?? 'Failed to accept flag');
        return false;
      }
    } catch (e) {
      _errorNotifier.setError('Error accepting flag: $e');
      return false;
    } finally {
      _loadingNotifier.setLoading(false);
    }
  }

  Future<bool> disputeFlag(
      String flagId, String evidence, String comments, {String? filePath}) async {
    try {
      _loadingNotifier.setLoading(true);
      _errorNotifier.clearError();

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
        _errorNotifier.setError(response.message ?? 'Failed to dispute flag');
        return false;
      }
    } catch (e) {
      _errorNotifier.setError('Error disputing flag: $e');
      return false;
    } finally {
      _loadingNotifier.setLoading(false);
    }
  }

  Future<bool> acknowledgeDisputeResolution(String pieceId) async {
    try {
      _loadingNotifier.setLoading(true);
      _errorNotifier.clearError();

      final response = await _pieceRepository.acknowledgeDisputeResolution(pieceId);

      if (response.isSuccess) {
        // Remove the piece from the list since it's now acknowledged
        state = state.where((piece) => piece.pieceId != pieceId).toList();
        return true;
      } else {
        _errorNotifier.setError(response.message ?? 'Failed to acknowledge dispute resolution');
        return false;
      }
    } catch (e) {
      _errorNotifier.setError('Error acknowledging dispute resolution: $e');
      return false;
    } finally {
      _loadingNotifier.setLoading(false);
    }
  }
}
