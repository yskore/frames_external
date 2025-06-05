import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:frames_app/core/config/app_config.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:http/http.dart' as http;

class iOSARCoreAuthService {
  // OAuth2 client credentials loaded from config
  late String _clientId;
  late String _reversedClientId;
  late String _bundleId;
  String? _cachedToken;
  DateTime? _tokenExpiry;
  
  // ARCore service account configuration
  late Map<String, dynamic> _arcoreServiceAccount;
  late String _audience;
  bool _initialized = false;
  
  // Singleton pattern
  static final iOSARCoreAuthService _instance = iOSARCoreAuthService._internal();
  factory iOSARCoreAuthService() => _instance;
  iOSARCoreAuthService._internal();
  
  /// Initialize authentication for iOS ARCore Extensions
  Future<bool> initialize() async {
    if (!Platform.isIOS) {
      if (kDebugMode) {
        print('[iOS Auth] Not on iOS platform, skipping initialization');
      }
      return false;
    }
    
    try {
      // Load configuration from AppConfig
      await _loadConfigFromAppConfig();
      
      if (!_initialized) {
        if (kDebugMode) {
          print('[iOS Auth] Failed to load iOS configuration');
        }
        return false;
      }
      
      if (kDebugMode) {
        print('[iOS Auth] ✅ iOS ARCore authentication configured successfully');
        print('[iOS Auth] Service account email: ${_arcoreServiceAccount['client_email']}');
        print('[iOS Auth] Audience: $_audience');
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('[iOS Auth] Error during initialization: $e');
      }
      return false;
    }
  }
  
  /// Load iOS configuration from AppConfig
  Future<void> _loadConfigFromAppConfig() async {
    try {
      final appConfig = AppConfig();
      
      // Ensure AppConfig is initialized
      if (!appConfig.isLoaded) {
        await appConfig.initialize();
      }
      
      // Get iOS configuration
      final iosConfig = appConfig.getConfig(['ios']);
      
      if (iosConfig == null) {
        throw Exception('iOS configuration not found in config file');
      }
      
      _clientId = iosConfig['client_id'] as String? ?? '';
      _reversedClientId = iosConfig['reversed_client_id'] as String? ?? '';
      _bundleId = iosConfig['bundle_id'] as String? ?? '';
      
      if (_clientId.isEmpty || _reversedClientId.isEmpty || _bundleId.isEmpty) {
        throw Exception('Incomplete iOS configuration - missing required fields');
      }
      
      // Get ARCore service account configuration
      final arcoreConfig = appConfig.getConfig(['arcore']);
      
      if (arcoreConfig == null) {
        throw Exception('ARCore configuration not found in config file');
      }
      
      _arcoreServiceAccount = arcoreConfig['service_account'] as Map<String, dynamic>;
      _audience = arcoreConfig['audience'] as String;
      
      if (_arcoreServiceAccount.isEmpty || _audience.isEmpty) {
        throw Exception('Incomplete ARCore configuration - missing service account or audience');
      }
      
      _initialized = true;
      
      if (kDebugMode) {
        print('[iOS Auth] Configuration loaded successfully');
        print('[iOS Auth] iOS Client ID: ${_clientId.substring(0, 20)}...');
        print('[iOS Auth] Bundle ID: $_bundleId');
        print('[iOS Auth] ARCore Service Account: ${_arcoreServiceAccount['client_email']}');
        print('[iOS Auth] ARCore Audience: $_audience');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[iOS Auth] Error loading configuration: $e');
      }
      _initialized = false;
      rethrow;
    }
  }
  
  /// Test the configuration by validating format
  bool validateConfiguration() {
    if (!_initialized) {
      if (kDebugMode) {
        print('[iOS Auth] ❌ Service not initialized');
      }
      return false;
    }
    
    // Validate Client ID format
    if (!_clientId.contains('.apps.googleusercontent.com')) {
      if (kDebugMode) {
        print('[iOS Auth] ❌ Invalid Client ID format');
      }
      return false;
    }
    
    // Validate Reversed Client ID format
    if (!_reversedClientId.startsWith('com.googleusercontent.apps.')) {
      if (kDebugMode) {
        print('[iOS Auth] ❌ Invalid Reversed Client ID format');
      }
      return false;
    }
    
    // Validate Bundle ID format
    if (!_bundleId.contains('.')) {
      if (kDebugMode) {
        print('[iOS Auth] ❌ Invalid Bundle ID format');
      }
      return false;
    }
    
    // Validate service account email
    if (!_arcoreServiceAccount['client_email'].toString().contains('@')) {
      if (kDebugMode) {
        print('[iOS Auth] ❌ Invalid service account email format');
      }
      return false;
    }
    
    // Validate audience URL
    if (!_audience.startsWith('https://')) {
      if (kDebugMode) {
        print('[iOS Auth] ❌ Invalid audience URL format');
      }
      return false;
    }
    
    if (kDebugMode) {
      print('[iOS Auth] ✅ All configuration values are valid');
    }
    
    return true;
  }
  
  /// Get device info for authentication
  Future<Map<String, String>> _getDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    
    if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return {
        'platform': 'iOS',
        'model': iosInfo.model,
        'systemVersion': iosInfo.systemVersion,
        'identifierForVendor': iosInfo.identifierForVendor ?? 'unknown',
        'bundleId': _bundleId,
      };
    }
    
    return {'platform': 'unknown'};
  }
  
  /// Get the client ID for external use (used by ARCore Extensions)
  String? get clientId => _initialized ? _clientId : null;
  
  /// Get the reversed client ID for external use (used in URL schemes)
  String? get reversedClientId => _initialized ? _reversedClientId : null;
  
  /// Get the bundle ID for external use
  String? get bundleId => _initialized ? _bundleId : null;
  
  /// Check if the service is properly initialized
  bool get isInitialized => _initialized;
  
  /// Get configuration summary for debugging
  Map<String, dynamic> getConfigSummary() {
    return {
      'initialized': _initialized,
      'clientId': _initialized ? '${_clientId.substring(0, 20)}...' : 'Not loaded',
      'bundleId': _initialized ? _bundleId : 'Not loaded',
      'serviceAccount': _initialized ? '${_arcoreServiceAccount['client_email']}' : 'Not loaded',
      'audience': _initialized ? _audience : 'Not loaded',
      'platform': Platform.isIOS ? 'iOS' : 'Not iOS',
    };
  }

  /// Get valid access token (cached or fresh)
  Future<String?> getValidAccessToken() async {
    if (_cachedToken != null && !_isTokenExpired()) {
      return _cachedToken;
    }
    
    // Generate new token
    _cachedToken = await generateAccessToken();
    _tokenExpiry = DateTime.now().add(Duration(minutes: 55)); // 5min buffer
    
    return _cachedToken;
  }
  
  bool _isTokenExpired() {
    return _tokenExpiry == null || DateTime.now().isAfter(_tokenExpiry!);
  }

  /// Generate JWT token for ARCore Cloud Anchors (for testing)
  Future<String?> generateJWTForTesting() async {
    if (!_initialized) {
      if (kDebugMode) print('[iOS Auth] Service not initialized');
      return null;
    }
    
    try {
      // Clean and format private key
      String privateKey = _arcoreServiceAccount['private_key'].replaceAll('\\n', '\n');
      
      if (!privateKey.startsWith('-----BEGIN PRIVATE KEY-----\n')) {
        throw Exception('Invalid private key format after cleaning');
      }
      
      // Create JWT with ARCore-specific claims
      final jwt = JWT({
        'iss': _arcoreServiceAccount['client_email'], // Service account email
        'sub': _arcoreServiceAccount['client_email'], // Same as iss for service accounts
        'aud': _audience, // https://arcore.googleapis.com/
        'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        'exp': DateTime.now().add(Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000,
      });
      
      // Return the JWT token directly (this is what you can test)
      final jwtToken = jwt.sign(RSAPrivateKey(privateKey), algorithm: JWTAlgorithm.RS256);
      
      if (kDebugMode) {
        print('[JWT Debug] Generated JWT token for ARCore: ${jwtToken.substring(0, 50)}...');
        print('[JWT Debug] Token parts: ${jwtToken.split('.').length}');
        print('[JWT Debug] Audience: $_audience');
        print('[JWT Debug] Issuer: ${_arcoreServiceAccount['client_email']}');
      }
      
      return jwtToken;
      
    } catch (e) {
      if (kDebugMode) print('[JWT Debug] Token generation error: $e');
      return null;
    }
  }

  /// Generate access token for ARCore Cloud Anchors (for actual use)
  Future<String?> generateAccessToken() async {
    if (!_initialized) {
      if (kDebugMode) print('[iOS Auth] Service not initialized');
      return null;
    }
    
    try {
      // Clean and format private key
      String privateKey = _arcoreServiceAccount['private_key'].replaceAll('\\n', '\n');
      
      if (!privateKey.startsWith('-----BEGIN PRIVATE KEY-----\n')) {
        throw Exception('Invalid private key format after cleaning');
      }
      
      // Create JWT with ARCore-specific claims
      final jwt = JWT({
        'iss': _arcoreServiceAccount['client_email'], // Service account email
        'sub': _arcoreServiceAccount['client_email'], // Same as iss for service accounts
        'aud': _audience, // https://arcore.googleapis.com/
        'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        'exp': DateTime.now().add(Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000,
      });
      
      final jwtToken = jwt.sign(RSAPrivateKey(privateKey), algorithm: JWTAlgorithm.RS256);
      
      // For ARCore, we can use the JWT directly as the auth token
      // ARCore expects a JWT, not an OAuth2 access token
      if (kDebugMode) {
        print('[ARCore Auth] Generated JWT token for ARCore authentication');
        print('[ARCore Auth] Token will be passed directly to ARAnchorManager.SetAuthToken()');
      }
      
      return jwtToken;
      
    } catch (e) {
      if (kDebugMode) print('[ARCore Auth] Token generation error: $e');
      return null;
    }
  }
}