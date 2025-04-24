import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frames_app/core/repositories/piece_repository.dart';
import 'package:frames_app/core/services/storage_service.dart';
import 'package:frames_app/models/frame_model.dart';
import 'package:frames_app/Providers/error_provider.dart';
import 'package:frames_app/Providers/loading_provider.dart';
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
    String pieceDisplay = " "//CHANGES: Changed PieceDisplay to String [URL]
  }) async {
    try {
      _loadingNotifier.setLoading(true);
      _errorNotifier.clearError();

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
        pieceImpressions: 0,
        pieceLocation: pieceLocation,
        pieceDescription: pieceDescription,
        pieceCreationDate: pieceCreationDate,
        pieceDisplay: pieceImageUrl,
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
      final currentFrames = _ref.read(framesProvider);
      if (currentFrames.isEmpty) {
        _loadingNotifier.setLoading(true);
        _errorNotifier.clearError();
      }

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

Future<Map<String, dynamic>?> getPieceDetails(String pieceId) async {
  try {
    _loadingNotifier.setLoading(true);
    _errorNotifier.clearError();
    
    final response = await _pieceRepository.getPieceById(pieceId);
    print('TEST: Full response: $response');
    
    if (response.isSuccess) {
      // Look at the raw response content
      print('TEST: Checking raw response structure');
      
      // If the response data exists
      if (response.data != null) {
        print('TEST: Response data exists');
        
        // Check if it has a 'piece' field
        if (response.data is Map<String, dynamic> && 
            (response.data as Map<String, dynamic>).containsKey('piece')) {
          print('TEST: Found piece data in response');
          return (response.data as Map<String, dynamic>)['piece'];
        }
        
        // Return the data as-is if no piece field
        return response.data as Map<String, dynamic>;
      }
    }
    
    _errorNotifier.setError(response.message ?? 'Failed to get piece details');
    return null;
  } catch (e) {
    _errorNotifier.setError('Error getting piece details: $e');
    return null;
  } finally {
    _loadingNotifier.setLoading(false);
  }
}
}
