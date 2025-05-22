import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:flutter_unity_widget/flutter_unity_widget.dart';

// Define scene types
enum UnitySceneType {
  previewScene,
  arScene,
}

// Extension to get the scene name string
extension SceneNameExtension on UnitySceneType {
  String get sceneName {
    switch (this) {
      case UnitySceneType.previewScene:
        return 'frames_test';
      case UnitySceneType.arScene:
        return 'frames_ar';
    }
  }
}

// Create a provider for the Unity scene manager
final unitySceneManagerProvider = Provider<UnitySceneManager>((ref) {
  return UnitySceneManager();
});

class UnitySceneManager {
  UnityWidgetController? _unityController;
  bool _isInitialized = false;
  UnitySceneType? _currentScene;
  bool _isDisposing = false; // Add this flag

  // Get the current scene
  UnitySceneType? get currentScene => _currentScene;

  // Check if Unity is initialized
  bool get isUnityInitialized => _isInitialized && _unityController != null;

  // Add these at the class level
  final _messageStreamController = StreamController<String>.broadcast();
  Stream<String> get sceneLoadedStream => _messageStreamController.stream;

// Create a method for handling Unity messages
  void handleUnityMessage(String message) {
    _messageStreamController.add(message);
    // Additional message handling logic
  }

  // Set the Unity controller
  void setController(UnityWidgetController controller) {
    _unityController = controller;
    _isInitialized = true;
  }

  // Get the Unity controller
  UnityWidgetController? getController() {
    return _unityController;
  }

  // Method to safely dispose the controller
  Future<void> safeDisposeController() async {
    if (_isDisposing) return; // Prevent multiple dispose calls

    _isDisposing = true;

    try {
      if (_unityController != null) {
        // First send a reset message
        _unityController!
            .postMessage('GameManager', 'ResetUnityScene', 'reset');

        // Small delay to allow Unity to process the message
        await Future.delayed(const Duration(milliseconds: 300));

        // Now actually dispose
        _unityController!.dispose();
        _unityController = null;
      }
    } catch (e) {
      print('Error disposing Unity controller: $e');
    } finally {
      _isInitialized = false;
      _isDisposing = false;
    }
  }

  // Load a Unity scene
  Future<bool> loadScene(UnitySceneType sceneType) async {
    if (!_isInitialized || _unityController == null) {
      if (kDebugMode) {
        print('[unity service] Unity controller not initialized');
      }
      return false;
    }

    try {
      // Create a completer to properly await scene loading
      final completer = Completer<bool>();

      // Set up a timeout in case the scene load callback doesn't fire
      Timer(const Duration(seconds: 5), () {
        if (!completer.isCompleted) {
          print('[unity service] Scene load timeout, proceeding anyway');
          completer.complete(true);
        }
      });

      // Set up a listener for scene loaded message
      final subscription = sceneLoadedStream.where((message) {
        return message == 'SCENE_SWITCHED' ||
            (message.startsWith('ACTIVE_SCENE:') &&
                message.contains(sceneType.sceneName));
      }).listen((_) {
        if (!completer.isCompleted) {
          _currentScene = sceneType;
          completer.complete(true);
        }
      });

      // Request scene change
      _unityController!.postMessage(
        'SceneLoader',
        'LoadSceneByName',
        sceneType.sceneName,
      );

      // Wait for scene load to complete
      final result = await completer.future;
      subscription.cancel();

      // Now that scene is loaded, we can safely set the view type
      if (result && sceneType == UnitySceneType.arScene) {
        // Add a small delay to ensure Unity has initialized all components
        await Future.delayed(const Duration(milliseconds: 500));
        setARViewType('general');
      }

      print('[unity service] Unity scene loaded: ${sceneType.sceneName}');
      return result;
    } catch (e) {
      if (kDebugMode) {
        print(' [unity service] Error loading Unity scene: $e');
      }
      return false;
    }
  }

  // Set the AR view type (general or placement)
  void setARViewType(String viewType) {
    if (!_isInitialized || _unityController == null) {
      if (kDebugMode) {
        print(' [unity service] Unity controller not initialized');
      }
      return;
    }

    try {
      if (_currentScene == UnitySceneType.arScene) {
        _unityController!.postMessage(
          'ARManager',
          'SetARViewType',
          viewType,
        );
        if (kDebugMode) {
          print('[unity service] Setting AR view type to: $viewType');
        }
      } else {
        if (kDebugMode) {
          print('[unity service] Cannot set AR view type: Not in AR scene');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('[unity service] Error setting AR view type: $e');
      }
    }
  }

  // Request the current view type from Unity
  void requestCurrentViewType() {
    if (!_isInitialized || _unityController == null) {
      if (kDebugMode) {
        print('[unity service] Unity controller not initialized');
      }
      return;
    }

    try {
      if (_currentScene == UnitySceneType.arScene) {
        _unityController!.postMessage(
          'ARManager',
          'GetCurrentViewType',
          '',
        );
        if (kDebugMode) {
          print('[unity service] Requesting current AR view type');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('[unity service] Error requesting AR view type: $e');
      }
    }
  }

  // Start GPS calibration
  void startCalibration() {
    if (!_isInitialized || _unityController == null) {
      if (kDebugMode) {
        print('Unity controller not initialized');
      }
      return;
    }

    try {
      if (_currentScene == UnitySceneType.arScene) {
        _unityController!.postMessage(
          'LocationManager',
          'StartCalibration',
          '',
        );
        if (kDebugMode) {
          print('Starting GPS calibration');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error starting calibration: $e');
      }
    }
  }

  // Load nearby pieces
  void loadNearbyPieces(String jsonData) {
    if (!_isInitialized || _unityController == null) {
      if (kDebugMode) {
        print('Unity controller not initialized');
      }
      return;
    }

    try {
      if (_currentScene == UnitySceneType.arScene) {
        _unityController!.postMessage(
          'EnhancedPieceLoader',
          'LoadNearbyPieces',
          jsonData,
        );
        if (kDebugMode) {
          print(
              '[unity service] Loading nearby pieces with data length: ${jsonData.length}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading nearby pieces: $e');
      }
    }
  }
}

class UnityWidgetController {
  postMessage(String s, String t, String jsonData) {}

  void dispose() {}
}
