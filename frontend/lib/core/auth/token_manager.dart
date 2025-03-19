import 'dart:developer';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenManager {
  static final TokenManager _instance = TokenManager._internal();
  factory TokenManager() => _instance;

  TokenManager._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Key constant
  static const String _accessTokenKey = 'access_token';
  static const String _username = 'username';

  String? _cachedAccessToken;
  String? _cachedUsername;

  bool get hasToken => _cachedAccessToken != null;

  String? get accessToken => _cachedAccessToken;
  String? get username => _cachedUsername;

  // Initialize by loading token from secure storage
  Future<void> initialize() async {
    try {
      _cachedAccessToken = await _storage.read(key: _accessTokenKey);
      _cachedUsername = await _storage.read(key: _username);
    } catch (e) {
      log('Error initializing token manager: $e', name: 'TokenManager');
    }
  }

  // Save access token
  Future<void> saveToken(String accessToken, String username) async {
    try {
      log('Saving access token and username $accessToken $username',
          name: 'TokenManager');
      await _storage.write(key: _accessTokenKey, value: accessToken);
      await _storage.write(key: _username, value: username);
      _cachedAccessToken = accessToken;
      _cachedUsername = username;
    } catch (e) {
      log('Error saving access token: $e', name: 'TokenManager');
    }
  }

  // Clear stored token
  Future<void> clearToken() async {
    try {
      await _storage.delete(key: _accessTokenKey);
      await _storage.delete(key: _username);
      _cachedAccessToken = null;
      _cachedUsername = null;
    } catch (e) {
      log('Error clearing access token: $e', name: 'TokenManager');
    }
  }
}
