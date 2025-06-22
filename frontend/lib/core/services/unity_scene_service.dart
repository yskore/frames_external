import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_unity_widget/flutter_unity_widget.dart';
import 'package:frames_app/core/auth/ios_arcore_authentication.dart';

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
  bool _isDisposing = false;
  bool _authTokenSet = false;
  bool _isControllerDisposed = false; // NEW: Track disposal state

  // Get the current scene
  UnitySceneType? get currentScene => _currentScene;
  
  // Check if Unity is initialized
  bool get isUnityInitialized => _isInitialized && _unityController != null && !_isControllerDisposed;

  // Add these at the class level
  final _messageStreamController = StreamController<String>.broadcast();
  Stream<String> get sceneLoadedStream => _messageStreamController.stream;

  // Create a method for handling Unity messages
  void handleUnityMessage(String message) {
    // Don't handle messages if disposing or disposed
    if (_isDisposing || _isControllerDisposed) {
      print('[unity service] Ignoring message during disposal: $message');
      return;
    }
    
    // Handle specific Unity messages
    if (message == 'REQUEST_AUTH_TOKEN') {
      _handleAuthTokenRequest();
    }
    // Additional message handling logic
  }

  Future<void> _handleAuthTokenRequest() async {
    print('[Unity Scene Service] Received auth token request from Unity');
    
    // Don't handle if disposing
    if (_isDisposing || _isControllerDisposed) {
      print('[Unity Scene Service] Ignoring auth token request during disposal');
      return;
    }
    
    if (Platform.isIOS) {
      try {
        final authService = iOSARCoreAuthService();
        
        if (!authService.isInitialized) {
          final initialized = await authService.initialize();
          if (!initialized) {
            print('[Unity Scene Service] Failed to initialize auth service');
            return;
          }
        }
        
        final token = await authService.getValidAccessToken();
        if (token != null && !_isControllerDisposed) {
          print('[Unity Scene Service] Sending auth token to Unity');
          safePostMessage('ARManager', 'SetAuthTokenVariable', token);
        } else {
          print('[Unity Scene Service] Failed to get auth token or controller disposed');
        }
      } catch (e) {
        print('[Unity Scene Service] Error handling auth token request: $e');
      }
    } else {
      print('[Unity Scene Service] Not on iOS, ignoring auth token request');
    }
  }

  // Set the Unity controller
  void setController(UnityWidgetController controller) {
    _unityController = controller;
    _isInitialized = true;
    _isControllerDisposed = false; // Reset disposal flag
  }

  // Get the Unity controller
  UnityWidgetController? getController() {
    return _isControllerDisposed ? null : _unityController;
  }

  // Method to safely dispose the controller
  Future<void> safeDisposeController() async {
    print('[unity service] Starting safe disposal of Unity controller');
    
    if (_isControllerDisposed || !_isInitialized) {
      print('[unity service] Controller already disposed or not initialized');
      return;
    }

    _isDisposing = true; // Set disposing flag

    try {
      if (_unityController != null) {
        // Give Unity a moment to finish any ongoing operations
        await Future.delayed(const Duration(milliseconds: 200));

        // Now dispose the controller
        try {
          _unityController!.dispose();
          print('[unity service] Unity controller disposed successfully');
        } catch (e) {
          print('[unity service] Error disposing controller (may already be disposed): $e');
        }
      }
    } catch (e) {
      print('[unity service] Error during safe disposal: $e');
    } finally {
      // Always reset state regardless of errors
      _unityController = null;
      _isInitialized = false;
      _currentScene = null;
      _isDisposing = false;
      _isControllerDisposed = true; // Mark as disposed
      print('[unity service] Unity service state reset');
    }
  }

  Future<bool> _testControllerResponsive() async {
    try {
      if (_unityController == null || _isControllerDisposed) return false;
      
      // Try a simple operation to test if controller is still valid
      // This will throw if the controller is disposed
      _unityController!.hashCode;
      return true;
    } catch (e) {
      print('[unity service] Controller is not responsive: $e');
      _isControllerDisposed = true; // Mark as disposed if test fails
      return false;
    }
  }

  // FIXED: More robust safe post message method
  bool safePostMessage(String gameObject, String methodName, String message) {
    // Check all disposal/initialization states
    if (!_isInitialized || _unityController == null || _isControllerDisposed || _isDisposing) {
      print('[unity service] Cannot post message: Unity not available (initialized: $_isInitialized, disposed: $_isControllerDisposed, disposing: $_isDisposing)');
      return false;
    }

    try {
      // Actually attempt the postMessage call - this is the real test
      _unityController!.postMessage(gameObject, methodName, message);
      return true;
    } catch (e) {
      print('[unity service] Error posting message to Unity: $e');
      // If postMessage fails, mark controller as disposed to prevent future attempts
      _isControllerDisposed = true;
      return false;
    }
  }

  // Modified loadScene method with auth token initialization
  Future<bool> loadScene(UnitySceneType sceneType) async {
    if (!_isInitialized || _unityController == null || _isControllerDisposed) {
      if (kDebugMode) {
        print('[unity service] Unity controller not available for scene loading');
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

      // Request scene change using safe post message
      bool messageSent = safePostMessage(
        'SceneLoader',
        'LoadSceneByName',
        sceneType.sceneName,
      );

      if (!messageSent) {
        subscription.cancel();
        return false;
      }

      // Wait for scene load to complete
      final result = await completer.future;
      subscription.cancel();

      // Now that scene is loaded, we can safely set the view type
      if (result && sceneType == UnitySceneType.arScene && !_isControllerDisposed) {
        // Add a small delay to ensure Unity has initialized all components
        await Future.delayed(const Duration(milliseconds: 500));
        
        setARViewType('general');
      }

      print('[unity service] Unity scene loaded: ${sceneType.sceneName}');
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('[unity service] Error loading Unity scene: $e');
      }
      return false;
    }
  }

  // Set the AR view type (general or placement)
  void setARViewType(String viewType) {
    if (!_isInitialized || _unityController == null || _isControllerDisposed) {
      if (kDebugMode) {
        print('[unity service] Unity controller not available for setting view type');
      }
      return;
    }

    try {
      if (_currentScene == UnitySceneType.arScene) {
        safePostMessage(
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
    if (!_isInitialized || _unityController == null || _isControllerDisposed) {
      if (kDebugMode) {
        print('[unity service] Unity controller not available for requesting view type');
      }
      return;
    }

    try {
      if (_currentScene == UnitySceneType.arScene) {
        safePostMessage(
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
    if (!_isInitialized || _unityController == null || _isControllerDisposed) {
      if (kDebugMode) {
        print('Unity controller not available for calibration');
      }
      return;
    }

    try {
      if (_currentScene == UnitySceneType.arScene) {
        safePostMessage(
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
    if (!_isInitialized || _unityController == null || _isControllerDisposed) {
      if (kDebugMode) {
        print('Unity controller not available for loading pieces');
      }
      return;
    }

    try {
      if (_currentScene == UnitySceneType.arScene) {
        safePostMessage(
          'EnhancedPieceLoader',
          'LoadNearbyPieces',
          jsonData,
        );
        if (kDebugMode) {
          print('[unity service] Loading nearby pieces with data length: ${jsonData.length}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading nearby pieces: $e');
      }
    }
  }
}
