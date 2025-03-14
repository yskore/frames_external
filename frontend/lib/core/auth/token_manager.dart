import 'dart:developer';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenManager {
  static final TokenManager _instance = TokenManager._internal();
  factory TokenManager() => _instance;

  TokenManager._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Key constant
  static const String _accessTokenKey = 'access_token';

  String? _cachedAccessToken;

  bool get hasToken => _cachedAccessToken != null;
  String? get accessToken => _cachedAccessToken;

  // Initialize by loading token from secure storage
  Future<void> initialize() async {
    try {
      _cachedAccessToken = await _storage.read(key: _accessTokenKey);
    } catch (e) {
      log('Error initializing token manager: $e', name: 'TokenManager');
    }
  }

  // Save access token
  Future<void> saveToken(String accessToken) async {
    try {
      await _storage.write(key: _accessTokenKey, value: accessToken);
      _cachedAccessToken = accessToken;
    } catch (e) {
      log('Error saving access token: $e', name: 'TokenManager');
    }
  }

  // Clear stored token
  Future<void> clearToken() async {
    try {
      await _storage.delete(key: _accessTokenKey);
      _cachedAccessToken = null;
    } catch (e) {
      log('Error clearing access token: $e', name: 'TokenManager');
    }
  }
}
