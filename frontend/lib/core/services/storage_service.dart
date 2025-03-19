import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:googleapis/storage/v1.dart' as storage;
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:path/path.dart' as path;

import '../config/app_config.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  late auth.ServiceAccountCredentials _credentials;
  final _scopes = [storage.StorageApi.devstorageFullControlScope];

  // Variable to store the name of the old image (for deletion)
  String? _oldImageName;

  // The variable to store the URL of the uploaded image
  String _tempPieceImage = '';

  Future<void> initialize() async {
    try {
      // Load credentials from app config
      final credentials = AppConfig().getConfig(['storage', 'credentials']);

      // Make sure the private key is properly formatted with newlines
      dynamic credentialsCopy = Map<String, dynamic>.from(credentials);
      if (credentialsCopy['private_key'] is String &&
          !credentialsCopy['private_key'].toString().contains(r'\n')) {}

      _credentials = auth.ServiceAccountCredentials.fromJson(credentialsCopy);
    } catch (e) {
      if (kDebugMode) {
        print('Failed to load storage credentials: $e');
      }
      rethrow;
    }
  }

  Future<storage.StorageApi> _authenticate() async {
    var httpClient = await auth.clientViaServiceAccount(_credentials, _scopes);
    return storage.StorageApi(httpClient);
  }

  Future<String> uploadImage(
      File imageFile, String bucketName, String folderName) async {
    try {
      final api = await _authenticate();

      final objectName = '$folderName/${path.basename(imageFile.path)}';
      final media = storage.Media(imageFile.openRead(), imageFile.lengthSync());

      await api.objects.insert(
        storage.Object()..name = objectName,
        bucketName,
        uploadMedia: media,
      );

      return 'https://storage.googleapis.com/$bucketName/$objectName';
    } catch (e) {
      if (kDebugMode) {
        print('Error uploading image: $e');
      }
      rethrow;
    }
  }

  Future<String> uploadPieceImage(
      File imageFile, String bucketName, String folderName) async {
    try {
      final client = await auth.clientViaServiceAccount(_credentials, _scopes);
      final storageApi = storage.StorageApi(client);

      // Delete the old image if it exists
      if (_oldImageName != null) {
        await storageApi.objects.delete(bucketName, _oldImageName!);
        _oldImageName = null;
      }

      // Upload the new image
      final media = storage.Media(imageFile.openRead(), imageFile.lengthSync());
      final response = await storageApi.objects.insert(
        storage.Object.fromJson(
            {'name': '$folderName/${imageFile.path.split('/').last}'}),
        bucketName,
        uploadMedia: media,
      );

      // Store the URL of the uploaded image
      _tempPieceImage = response.mediaLink!;

      // Store the name of the uploaded image
      _oldImageName = response.name;

      client.close();

      return _tempPieceImage;
    } catch (e) {
      if (kDebugMode) {
        print('Error uploading piece image: $e');
      }
      rethrow;
    }
  }

  // Clear cached image data
  void clearCachedImages() {
    _oldImageName = null;
    _tempPieceImage = '';
  }

  // Getter for the last uploaded piece image
  String get lastUploadedPieceImage => _tempPieceImage;
}
