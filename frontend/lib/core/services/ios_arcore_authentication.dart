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
  
  // For ARCore Cloud Anchors, we primarily need the API key from Google Cloud Console
  String? _apiKey;
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
        print('[iOS Auth] This service provides OAuth configuration for ARCore');
        print('[iOS Auth] Actual authentication is handled by ARCore Extensions SDK');
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
      
      // Try to get API key from config if available
      try {
        _apiKey = iosConfig['api_key'] as String?;
      } catch (e) {
        // API key is optional in config, can be set in Google Cloud Console
        if (kDebugMode) {
          print('[iOS Auth] No API key found in config (this is normal)');
        }
      }
      
      _initialized = true;
      
      if (kDebugMode) {
        print('[iOS Auth] Configuration loaded successfully');
        print('[iOS Auth] Client ID: ${_clientId.substring(0, 20)}...');
        print('[iOS Auth] Bundle ID: $_bundleId');
        print('[iOS Auth] API Key: ${_apiKey != null ? "Set" : "Not set (will use Google Cloud Console setting)"}');
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
  
  /// Get the API key if configured
  String? get apiKey => _apiKey;
  
  /// Check if the service is properly initialized
  bool get isInitialized => _initialized;
  
  /// Get configuration summary for debugging
  Map<String, dynamic> getConfigSummary() {
    return {
      'initialized': _initialized,
      'clientId': _initialized ? '${_clientId.substring(0, 20)}...' : 'Not loaded',
      'bundleId': _initialized ? _bundleId : 'Not loaded',
      'apiKey': _apiKey != null ? 'Set' : 'Not set',
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

 /// Generate access token for ARCore Cloud Anchors
Future<String?> generateAccessToken() async {
  try {
    final appConfig = AppConfig();
    final credentials = appConfig.getConfig(['storage', 'credentials']);
    
    // Debug private key
    String rawKey = credentials['private_key'];
    print('[Debug] Raw key length: ${rawKey.length}');
    print('[Debug] First 50 chars: ${rawKey.substring(0, 50)}');
    
    // Clean and format private key
String privateKey = rawKey.replaceAll('\\n', '\n');

print('[Debug] After newline fix: ${privateKey.substring(0, 50)}');

if (!privateKey.startsWith('-----BEGIN PRIVATE KEY-----\n')) {
  throw Exception('Invalid private key format after cleaning');
}
    
    print('[Debug] Cleaned key starts with: ${privateKey.substring(0, 27)}');
    
    // Create JWT
    final jwt = JWT({
      'iss': credentials['client_email'],
      'scope': 'https://www.googleapis.com/auth/cloud-platform',
      'aud': 'https://oauth2.googleapis.com/token',
      'exp': DateTime.now().add(Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000,
      'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    });
    
  final token = jwt.sign(RSAPrivateKey(privateKey), algorithm: JWTAlgorithm.RS256);    
    final response = await http.post(
  Uri.parse('https://oauth2.googleapis.com/token'),
  headers: {'Content-Type': 'application/x-www-form-urlencoded'},
  body: {
    'grant_type': 'urn:ietf:params:oauth:grant-type:jwt-bearer',
    'assertion': token,
  },
);

print('[Debug] HTTP Status: ${response.statusCode}');
print('[Debug] HTTP Response: ${response.body}');

if (response.statusCode == 200) {
  final data = jsonDecode(response.body);
  return data['access_token'];
}
    return null;
  } catch (e) {
    if (kDebugMode) print('[iOS Auth] Token generation error: $e');
    return null;
  }
}


}