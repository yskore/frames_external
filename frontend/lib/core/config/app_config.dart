import 'dart:developer';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:yaml/yaml.dart';

class ConfigException implements Exception {
  final String message;
  ConfigException(this.message);

  @override
  String toString() => 'ConfigException: $message';
}

class AppConfig {
  // Environment constants
  static const _dev = 'dev';
  static const _prod = 'prod';

  // Environment argument name
  static const _environmentArgName = 'env';

  static final AppConfig _instance = AppConfig._internal();
  factory AppConfig() => _instance;

  AppConfig._internal();

  late Map<String, dynamic> _config;
  bool _isLoaded = false;
  late String _environment;

  bool get isLoaded => _isLoaded;
  String get environment => _environment;

  /// Get a specific configuration value by key path
  /// Example: getConfig(['api', 'base_url'])
  dynamic getConfig(List<String> keyPath) {
    if (!_isLoaded) {
      throw ConfigException('Attempting to access config before it was loaded');
    }

    // Get environment-specific configuration directly
    try {
      List<String> envKeyPath = [...keyPath];

      // First element of keyPath should be the configuration section (api, smtp, etc)
      if (keyPath.isNotEmpty) {
        String section = keyPath[0];
        envKeyPath = [section, _environment, ...keyPath.sublist(1)];
      }

      return _getConfigValue(envKeyPath);
    } catch (e) {
      // Fall back to default config if environment-specific one is not found
      try {
        return _getConfigValue(keyPath);
      } catch (e) {
        throw ConfigException(
            'Config value not found for path: $keyPath in environment: $_environment');
      }
    }
  }

  /// Internal helper to navigate config paths
  dynamic _getConfigValue(List<String> keyPath) {
    dynamic currentValue = _config;
    for (final key in keyPath) {
      if (currentValue is! Map) {
        throw ConfigException('Invalid config path: $keyPath');
      }
      currentValue = currentValue[key];
      if (currentValue == null) {
        throw ConfigException('Config value not found for path: $keyPath');
      }
    }
    return currentValue;
  }

  /// Logs the entire configuration for debugging purposes
  void logAllConfig() {
    if (!_isLoaded) {
      log('Config not loaded yet, cannot log', name: 'AppConfig');
      return;
    }

    log('===== COMPLETE CONFIGURATION =====', name: 'AppConfig');
    log('Environment: $_environment', name: 'AppConfig');
    _logConfigMap(_config, '');
    log('=================================', name: 'AppConfig');
  }

  /// Helper method to recursively log configuration map with indentation
  void _logConfigMap(dynamic configMap, String indent) {
    if (configMap is Map) {
      configMap.forEach((key, value) {
        if (value is Map) {
          log('$indent$key:', name: 'AppConfig');
          _logConfigMap(value, '$indent  ');
        } else {
          log('$indent$key: $value', name: 'AppConfig');
        }
      });
    }
  }

  /// Get API specific configuration
  Map<String, dynamic> get apiConfig {
    final config = getConfig(['api']);
    if (config is! Map<String, dynamic>) {
      throw ConfigException('API config is not a map');
    }
    return config;
  }

  /// Get Storage specific configuration
  Map<String, dynamic> get storageConfig {
    final config = getConfig(['storage']);
    if (config is! Map<String, dynamic>) {
      throw ConfigException('Storage config is not a map');
    }
    return config;
  }

  /// Get SMTP specific configuration
  Map<String, dynamic> get smtpConfig {
    final config = getConfig(['smtp']);
    if (config is! Map<String, dynamic>) {
      throw ConfigException('SMTP config is not a map');
    }
    return config;
  }

  /// Initialize the configuration, detecting environment using String.fromEnvironment
  Future<void> initialize() async {
    // Detect environment using String.fromEnvironment
    _detectEnvironment();

    try {
      _config = await _loadConfig();
      _isLoaded = true;
      log('Configuration loaded successfully for environment: $_environment',
          name: 'AppConfig');
    } catch (e) {
      log('Failed to load configuration: $e', name: 'AppConfig');
      throw ConfigException('Failed to load configuration: $e');
    }
  }

  /// Detect environment using String.fromEnvironment
  /// Can be set at compile time using --dart-define=env=dev
  void _detectEnvironment() {
    // Get environment from compile-time argument with default to prod
    _environment =
        const String.fromEnvironment(_environmentArgName, defaultValue: _prod);

    // Validate environment value (only prod and dev are supported)
    if (_environment != _dev && _environment != _prod) {
      log('Invalid environment: $_environment, using $_prod instead',
          name: 'AppConfig');
      _environment = _prod;
    }

    log('Using environment: $_environment', name: 'AppConfig');
  }

  /// Set the current environment manually
  void setEnvironment(String env) {
    if (env != _dev && env != _prod) {
      throw ConfigException(
          'Invalid environment: $env. Only $_dev and $_prod are supported.');
    }

    if (_isLoaded) {
      log('Warning: Changing environment after config is loaded may require reinitialization',
          name: 'AppConfig');
    }
    _environment = env;
  }

  /// Load configuration from file
  Future<Map<String, dynamic>> _loadConfig() async {
    // Try to load from file system first (root folder)
    try {
      final configFile = File('config.yaml');
      if (await configFile.exists()) {
        final yamlString = await configFile.readAsString();
        return _convertYaml(loadYaml(yamlString));
      }
    } catch (e) {
      log('Error loading config from root directory: $e', name: 'AppConfig');
    }

    // If root file doesn't work, try asset
    try {
      final yamlString = await rootBundle.loadString('config.yaml');
      return _convertYaml(loadYaml(yamlString));
    } catch (e) {
      log('Error loading config as asset: $e', name: 'AppConfig');
      throw ConfigException('Could not load configuration file: $e');
    }
  }

  /// Convert YAML to a regular Dart Map
  Map<String, dynamic> _convertYaml(YamlMap yamlMap) {
    final map = <String, dynamic>{};

    for (final entry in yamlMap.entries) {
      if (entry.value is YamlMap) {
        map[entry.key.toString()] = _convertYaml(entry.value as YamlMap);
      } else {
        map[entry.key.toString()] = entry.value;
      }
    }

    return map;
  }
}
