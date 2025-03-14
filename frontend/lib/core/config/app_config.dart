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
  static final AppConfig _instance = AppConfig._internal();
  factory AppConfig() => _instance;

  AppConfig._internal();

  late Map<String, dynamic> _config;
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;

  /// Get a specific configuration value by key path
  /// Example: getConfig(['api', 'base_url'])
  dynamic getConfig(List<String> keyPath) {
    if (!_isLoaded) {
      throw ConfigException('Attempting to access config before it was loaded');
    }

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

  /// Get API specific configuration
  Map<String, dynamic> get apiConfig {
    final config = getConfig(['api']);
    if (config is! Map<String, dynamic>) {
      throw ConfigException('API config is not a map');
    }
    return config;
  }

  /// Initialize the configuration
  Future<void> initialize() async {
    try {
      _config = await _loadConfig();
      _isLoaded = true;
      log('Configuration loaded successfully', name: 'AppConfig');
    } catch (e) {
      log('Failed to load configuration: $e', name: 'AppConfig');
      throw ConfigException('Failed to load configuration: $e');
    }
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
