import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../repositories/storage_repository.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final StorageRepository _storageRepository = StorageRepository();

  // The variable to store the URL of the uploaded image
  String _tempPieceImage = '';

  Future<String> uploadImage(
      File imageFile, String bucketName, String folderName) async {
    try {
      final response = await _storageRepository.uploadImage(
        imageFile: imageFile,
        folderName: folderName,
      );

      if (response.isSuccess && response.data != null) {
        return response.data!['imageUrl'];
      } else {
        throw Exception(response.message ?? 'Failed to upload image');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error uploading image: $e');
      }
      rethrow;
    }
  }

  Future<String> uploadPieceImage(
      File imageFile, String bucketName, String folderName,
      [String? pieceId]) async {
    try {
      final response = await _storageRepository.uploadImage(
        imageFile: imageFile,
        folderName: folderName,
        resourceId: pieceId,
        resourceType: 'piece',
      );

      if (response.isSuccess && response.data != null) {
        _tempPieceImage = response.data!['imageUrl'];
        return _tempPieceImage;
      } else {
        throw Exception(response.message ?? 'Failed to upload piece image');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error uploading piece image: $e');
      }
      rethrow;
    }
  }

  void clearCachedImages() {
    _tempPieceImage = '';
  }

  String get lastUploadedPieceImage => _tempPieceImage;
}
