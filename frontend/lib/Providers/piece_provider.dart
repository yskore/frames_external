import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frames_app/core/repositories/piece_repository.dart';
import 'package:frames_app/core/services/storage_service.dart';
import 'package:frames_app/models/frame_model.dart';
import 'package:frames_app/providers/error_provider.dart';
import 'package:frames_app/providers/loading_provider.dart';
import 'package:frames_app/providers/user_provider.dart';
import 'package:intl/intl.dart';

const kPieceBucketName = 'x-fabric-419423.appspot.com';
const kPieceFolderName = 'piece_display';
const kTempPieceFolderName = 'temp_image_upload';

// Store frames data in a provider with the proper type
final framesProvider = StateProvider<List<Frame>>((ref) => []);

final pieceProvider = StateNotifierProvider<PieceNotifier, void>((ref) {
  final pieceRepository = ref.read(pieceRepositoryProvider);
  final loadingNotifier = ref.read(loadingProvider.notifier);
  final userNotifier = ref.read(userProvider.notifier);
  final errorNotifier = ref.read(errorProvider.notifier);

  return PieceNotifier(
      pieceRepository, loadingNotifier, errorNotifier, userNotifier, ref);
});

class PieceNotifier extends StateNotifier<void> {
  final PieceRepository _pieceRepository;
  final LoadingNotifier _loadingNotifier;
  final ErrorNotifier _errorNotifier;
  final UserNotifier _userNotifier;
  final Ref _ref;
  final _storageService = StorageService();

  PieceNotifier(
    this._pieceRepository,
    this._loadingNotifier,
    this._errorNotifier,
    this._userNotifier,
    this._ref,
  ) : super(null);

  Future<bool> createPiece({
    required String pieceTitle,
    required String frameName,
    required String faceName,
    required String pieceDescription,
    required String pieceLocation,
    required bool pieceForSale,
    required double piecePrice,
    required File pieceImage,
    required String pieceOwner,
    bool liveStatus = false,
    bool pieceDisplay = true,
  }) async {
    try {
      _loadingNotifier.setLoading(true);
      _errorNotifier.clearError();

      // Upload image first
      final String pieceImageUrl = await _storageService.uploadPieceImage(
        pieceImage,
        kPieceBucketName,
        kPieceFolderName,
      );

      // Format current date
      final String pieceCreationDate =
          DateFormat('yyyy-MM-dd').format(DateTime.now());

      final serializedObjectData = jsonEncode({
        'frameName': frameName,
        'faceName': faceName,
        'imageUrl': pieceImageUrl,
        'position': {'x': 0, 'y': 0, 'z': 0},
        'rotation': {'x': 0, 'y': 0, 'z': 0, 'w': 1},
        'scale': {'x': 1, 'y': 1, 'z': 1},
        'geolocation': {
          'latitude': 0.0, // Will be updated when placed in AR
          'longitude': 0.0 // Will be updated when placed in AR
        }
      });
      // Create piece using repository
      final response = await _pieceRepository.createPiece(
        pieceObject: serializedObjectData,
        pieceOwner: pieceOwner,
        pieceTitle: pieceTitle,
        frameName: frameName,
        liveStatus: liveStatus,
        pieceLikes: 0,
        pieceLocation: pieceLocation,
        pieceDescription: pieceDescription,
        pieceCreationDate: pieceCreationDate,
        pieceDisplay: pieceDisplay,
        pieceForSale: pieceForSale,
        piecePrice: piecePrice,
      );

      if (response.isSuccess) {
        await _userNotifier.refreshUserData();
        return true;
      }

      _errorNotifier.setError(response.message ?? 'Failed to create piece');
      return false;
    } catch (e) {
      _errorNotifier.setError('Error creating piece: $e');
      return false;
    } finally {
      _loadingNotifier.setLoading(false);
    }
  }

  Future<String?> uploadPieceImage(File imageFile) async {
    try {
      _loadingNotifier.setLoading(true);
      _errorNotifier.clearError();
      return await _storageService.uploadPieceImage(
        imageFile,
        kPieceBucketName,
        kTempPieceFolderName,
      );
    } catch (e) {
      _errorNotifier.setError('Error uploading piece image: $e');
      return null;
    } finally {
      _loadingNotifier.setLoading(false);
    }
  }

  Future<bool> fetchFrames() async {
    try {
      _loadingNotifier.setLoading(true);
      _errorNotifier.clearError();

      final response = await _pieceRepository.fetchFrames();

      if (response.isSuccess &&
          response.data != null &&
          response.data!['frames'] != null) {
        final List<dynamic> framesJson =
            response.data!['frames'] as List<dynamic>;
        final frames = framesJson.map((json) => Frame.fromJson(json)).toList();

        _ref.read(framesProvider.notifier).state = frames;
        return true;
      }

      _errorNotifier.setError(response.message ?? 'Failed to fetch frames');
      return false;
    } catch (e) {
      _errorNotifier.setError('Error fetching frames: $e');
      return false;
    } finally {
      _loadingNotifier.setLoading(false);
    }
  }
}
