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
  bool _isDisposing = false; // Add this flag
  bool _authTokenSet = false; // Track if auth token has been set


  // Get the current scene
  UnitySceneType? get currentScene => _currentScene;
  
  // Check if Unity is initialized
  bool get isUnityInitialized => _isInitialized && _unityController != null;

  // Add these at the class level
final _messageStreamController = StreamController<String>.broadcast();
Stream<String> get sceneLoadedStream => _messageStreamController.stream;

// Create a method for handling Unity messages
void handleUnityMessage(String message) {
 // _messageStreamController.add(message);
  
  // Handle specific Unity messages
  if (message == 'REQUEST_AUTH_TOKEN') {
    _handleAuthTokenRequest();
  }
  // Additional message handling logic
}
/** 
  Future<void> _initializeAuthToken() async {
  print('geo [Unity Scene Manager] Initializing auth token for AR scene');
  
  try {
    final authService = iOSARCoreAuthService();
    
    if (!authService.isInitialized) {
      final initialized = await authService.initialize();
      if (!initialized) {
        print('[Unity Scene Manager] Failed to initialize auth service');
        return;
      }
    }
    
    final token = await authService.getValidAccessToken();
    if (token != null) {
      _unityController?.postMessage('ARManager', 'SetAuthTokenVariable', token);
      _authTokenSet = true;
      print('[Unity Scene Manager] Auth token set before AR scene load');
    }
  } catch (e) {
    print('[Unity Scene Manager] Error initializing auth token: $e');
  }
}
*/



 Future<void> _handleAuthTokenRequest() async {
  print('[Unity Scene Service] Received auth token request from Unity');
  
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
      if (token != null) {
        print('[Unity Scene Service] Sending auth token to Unity');
        _unityController?.postMessage('ARManager', 'SetAuthTokenVariable', token);
      } else {
        print('[Unity Scene Service] Failed to get auth token');
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
        _unityController!.postMessage(
          'GameManager',
          'ResetUnityScene',
          'reset'
        );
        
        // Small delay to allow Unity to process the message
        await Future.delayed(const Duration(milliseconds: 300));
        
        // Now actually dispose
        _unityController!.dispose();
        _unityController = null;

        print("[TEST] safeDisposeController called and unity controller disposed");
      }

       _isInitialized = false;
      _currentScene = null;
      _authTokenSet = false;
    } catch (e) {
      print('Error disposing Unity controller: $e');
    } finally {
      _isInitialized = false;
      _isDisposing = false;
    }
  }

   // Modified loadScene method with auth token initialization
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
      
      // Initialize auth token for AR scene
      //await _initializeAuthToken();
      
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
          print('[unity service] Loading nearby pieces with data length: ${jsonData.length}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading nearby pieces: $e');
      }
    }
  }
    // Safe disposal method
  
}
