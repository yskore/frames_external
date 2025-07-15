import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_unity_widget/flutter_unity_widget.dart';
import 'package:frames_app/Functions/piece_anchoring.dart';
import 'package:frames_app/Functions/toggle_live_status.dart';
import 'package:frames_app/Providers/error_provider.dart';
import 'package:frames_app/core/auth/ios_arcore_authentication.dart';
import 'package:frames_app/core/mixins/message_mixin.dart';
import 'package:frames_app/core/repositories/anchor_repository.dart';
import 'package:frames_app/core/repositories/piece_repository.dart';
import 'package:frames_app/core/services/unity_scene_service.dart';
import 'package:frames_app/ui/Screens/user_profile_screen.dart';
import 'package:frames_app/ui/Widgets/placementErrorWidget.dart';
import 'package:frames_app/ui/Widgets/unified_unity_view.dart';
import 'package:frames_app/utils/permissions_utils.dart';
import 'package:permission_handler/permission_handler.dart';

class UnityARViewPlacement extends ConsumerStatefulWidget {
  final String pieceData;
  final String username;

  const UnityARViewPlacement({
    super.key,
    required this.pieceData,
    required this.username,
  });

  @override
  UnityARViewPlacementState createState() => UnityARViewPlacementState();
}

class UnityARViewPlacementState extends ConsumerState<UnityARViewPlacement>
    with MessageMixin {
  // State variables
  bool _isARSceneLoaded = false;
  bool _isLoading = true;
  bool _isUnityInitialized = false;
  bool _isSceneReady = false;
  String _arSessionState = "Unknown";
  bool _surfaceDetected = false;
  bool _isFrameLoaded = false;
  String _currentScene = 'not set';
  String _currentViewType = 'not set';
  final bool _hasPermissions = true;
  String _errorMessage = '';

  // State variables for posting process
  bool _isPosting = false;
  bool _anchorDataReceived = false;
  bool _anchorSuccessfullySaved = false;
  String? _anchorError;

  // Cloud anchor status
  String _cloudAnchorStatus = "";
  int _cloudAnchorWaitTime = 0;
  String? _cloudAnchorId;
  String _cloudAnchorSubStatus = "";
  int _cloudAnchorSubProgress = 0;
  int _cloudAnchorSubTotal = 0;

  // Geospatial anchor status
  String _geospatialStatus = "";
  String _geospatialSubStatus = "";
  double _locationAccuracy = 0.0;
  double _orientationAccuracy = 0.0;
  bool _vpsAvailable = false;

  @override
  void initState() {
    super.initState();
    // setAuthToken();

    // Load the Unity AR scene when widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadARScene();
    });
  }

  // Unity Scene Management with SceneManager
  void _loadARScene() async {
    setState(() {
      _isLoading = true;
      _isUnityInitialized = false;
    });

    try {
      final sceneManager = ref.read(unitySceneManagerProvider);

      if (sceneManager.isUnityInitialized) {
        // Check if already in AR scene
        if (sceneManager.currentScene != UnitySceneType.arScene) {
          print('[LOGS] Loading AR scene from SceneManager');

          // Load the AR scene
          final success = await sceneManager.loadScene(UnitySceneType.arScene);

          if (success) {
            setState(() {
              _isUnityInitialized = true;
              _isSceneReady = true;
              _isLoading = false;
            });

            // Set AR view type to placement after scene loads
            Future.delayed(const Duration(milliseconds: 500), () {
              _setPlacementViewType();
            });
          } else {
            setErrorMessage('Failed to load AR scene');
          }
        } else {
          // Already in AR scene, just set view type
          setState(() {
            _isUnityInitialized = true;
            _isSceneReady = true;
            _isLoading = false;
          });

          _setPlacementViewType();
        }
      } else {
        print(
            '[LOGS] Unity not initialized yet, will wait for UnityWidget creation');
      }
    } catch (e) {
      setErrorMessage('Error loading AR scene: $e');
    }
  }

  void _setPlacementViewType() {
    final sceneManager = ref.read(unitySceneManagerProvider);

    if (sceneManager.isUnityInitialized) {
      sceneManager.setARViewType('placement');

      // Request current view type to update state
      Future.delayed(const Duration(milliseconds: 200), () {
        sceneManager.requestCurrentViewType();
      });
    }
  }

  void setErrorMessage(String message) {
    setState(() {
      _errorMessage = message;
      _isLoading = false;
    });
    print('Error: $message');
  }
/** 
  Future<void> setAuthToken() async {
    print('[iOS Auth] Received auth token request from Unity (AR Placement)');
    
    if (Platform.isIOS) {
      try {
        final authService = iOSARCoreAuthService();
        
        // Initialize the service if not already done
        if (!authService.isInitialized) {
          final initialized = await authService.initialize();
          if (!initialized) {
            print('[iOS Auth] Failed to initialize auth service');
            return;
          }
        }
        
        // Generate ARCore auth token (JWT)
        final token = await authService.getValidAccessToken();
        if (token != null) {
          print('Geo [iOS Auth] Generated auth token, sending to Unity');
          
          final sceneManager = ref.read(unitySceneManagerProvider);
          if (sceneManager.isUnityInitialized) {
            final controller = sceneManager.getController();
            
            controller?.postMessage(
              'ARManager',  
              'SetAuthToken',        
              token,
            );
            
            print('Geo [iOS Auth] Auth token sent to Unity via multiple methods');
          } else {
            print('Geo [iOS Auth] Unity not initialized, cannot send token');
          }
        } else {
          print('Geo [iOS Auth] Failed to generate auth token');
        }
      } catch (e) {
        print('geo [iOS Auth] Error handling auth token request: $e');
      }
    } else {
      print('geo [iOS Auth] Not on iOS platform, ignoring auth token request');
    }
  }
  */

  // Method for unified cleanup and navigation
  Future<void> _cleanupAndNavigate() async {
    print('[AR placement] Starting cleanup and navigation');

    final sceneManager = ref.read(unitySceneManagerProvider);

    try {
      if (sceneManager.isUnityInitialized) {
        print('[AR placement] Unity is initialized, starting safe disposal');

        // Give Unity a moment to finish any ongoing operations
        await Future.delayed(const Duration(milliseconds: 200));

        // Now safely dispose
        await sceneManager.safeDisposeController();
      } else {
        print('[AR placement] Unity not initialized, skipping disposal');
      }

      // Navigate after cleanup
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const UserProfileScreen(),
          ),
        );
        print('[AR placement] Navigation completed');
      }
    } catch (e) {
      print('[AR placement] Error during cleanup: $e');
      // Even if cleanup fails, try to navigate
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const UserProfileScreen(),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _handleUnityMessage(String message) async {
    print('Unity message: $message');

    final sceneManager = ref.read(unitySceneManagerProvider);
    sceneManager.handleUnityMessage(message);
    if (message == 'AR_COMPONENTS_INITIALIZED') {
      setState(() {
        _isARSceneLoaded = true;
        _isLoading = false;
      });
    } else if (message.startsWith('AR_SESSION_STATE:')) {
      setState(() {
        _arSessionState = message.split(':')[1];
      });
    } else if (message == 'AR_SURFACE_DETECTED') {
      setState(() {
        _surfaceDetected = true;
      });
    } else if (message == 'AR_INITIALIZATION_FAILED') {
      print('AR initialization failed');
    } else if (message == 'FRAME_LOADED') {
      setState(() {
        _isFrameLoaded = true;
      });
    } else if (message.startsWith('CURRENT_VIEW_TYPE:')) {
      String viewType = message.split(':')[1];
      print('Current AR View Type: $viewType');
      setState(() {
        _currentViewType = viewType;
      });
    }
    // Handle scene messages
    else if (message.startsWith('ACTIVE_SCENE:')) {
      String activeScene = message.split(':')[1];
      setState(() {
        _currentScene = activeScene;
      });
      if (activeScene == 'frames_ar') {
        setState(() {
          _isARSceneLoaded = true;
          _isLoading = false;
        });
        print('Current AR scene loaded: $activeScene');
        _setPlacementViewType();
      } else {
        print('Wrong scene loaded: $activeScene - switching to frames_ar');
        _switchToARScene();
      }
    } else if (message == 'SCENE_SWITCHED') {
      setState(() {
        _isARSceneLoaded = true;
        _isLoading = false;
      });
      print('Scene switched to frames_ar');
      _setPlacementViewType();
    }
    // Geospatial anchor messages
    else if (message.startsWith('GEOSPATIAL_STATUS:')) {
      final parts = message.split(':');
      if (parts.length >= 2) {
        final status = parts[1];
        setState(() {
          _geospatialStatus = status;
        });

        // Handle specific geospatial statuses
        if (status == "INITIALIZING") {
          setState(() {
            _geospatialSubStatus = "Starting geospatial tracking...";
          });
        } else if (status == "LOCALIZED") {
          setState(() {
            _geospatialSubStatus = "Location tracking active";
          });
        } else if (status == "NOT_TRACKING") {
          setState(() {
            _geospatialSubStatus = "Unable to track location";
          });
        }
      }
    } else if (message.startsWith('GEOSPATIAL_ACCURACY:')) {
      final parts = message.split(':');
      if (parts.length >= 3) {
        try {
          final locAccuracy = double.parse(parts[1]);
          final oriAccuracy = double.parse(parts[2]);
          setState(() {
            _locationAccuracy = locAccuracy;
            _orientationAccuracy = oriAccuracy;
          });
        } catch (e) {
          print('Error parsing geospatial accuracy: $e');
        }
      }
    } else if (message.startsWith('VPS_AVAILABILITY:')) {
      final available = message.split(':')[1] == "true";
      setState(() {
        _vpsAvailable = available;
      });
    } else if (message.startsWith('TERRAIN_ANCHOR_STATUS:')) {
      final parts = message.split(':');
      if (parts.length >= 2) {
        final status = parts[1];
        setState(() {
          _geospatialSubStatus = status;
        });

        if (status == "SUCCESS") {
          setState(() {
            _geospatialStatus = "SUCCESS";
          });
        } else if (status.startsWith("ERROR")) {
          setState(() {
            _geospatialStatus = "ERROR:$status";
          });
        }
      }
    }
    // Cloud anchor messages (existing)
    else if (message.startsWith('CLOUD_ANCHOR_WARNING:')) {
      final warningMessage = message.split(':')[1];
      print('Cloud anchor warning: $warningMessage');
      setState(() {
        _cloudAnchorStatus = "WARNING";
      });
    } else if (message.startsWith('CLOUD_ANCHOR_SCANNING:')) {
      final parts = message.split(':');
      if (parts.length >= 3) {
        try {
          final current = double.parse(parts[1]);
          final total = double.parse(parts[2]);
          setState(() {
            _cloudAnchorSubStatus = "SCANNING";
            _cloudAnchorSubProgress = current.round();
            _cloudAnchorSubTotal = total.round();
          });
        } catch (e) {
          print('Error parsing scanning progress: $e');
        }
      }
    } else if (message.startsWith('CLOUD_ANCHOR_STATUS:STABILIZING:')) {
      final parts = message.split(':');
      if (parts.length >= 4) {
        try {
          final current = int.parse(parts[2]);
          final total = int.parse(parts[3]);
          setState(() {
            _cloudAnchorSubStatus = "STABILIZING";
            _cloudAnchorSubProgress = current;
            _cloudAnchorSubTotal = total;
          });
        } catch (e) {
          print('Error parsing stabilizing progress: $e');
        }
      }
    } else if (message.startsWith('CLOUD_ANCHOR_STATUS:')) {
      final parts = message.split(':');
      final status = parts[1];
      setState(() {
        _cloudAnchorStatus = status;
        if (status != "SCANNING" && status != "STABILIZING") {
          _cloudAnchorSubStatus = "";
        }
        if (status == "WAITING" && parts.length > 2) {
          _cloudAnchorWaitTime = int.tryParse(parts[2]) ?? 0;
        } else if (status == "SUCCESS" && parts.length > 2) {
          _cloudAnchorId = parts[2];
        }
      });
    } else if (message.startsWith('CLOUD_ANCHOR_ERROR:')) {
      final errorMessage = message.split(':')[1];
      print('Cloud anchor error: $errorMessage');
      setState(() {
        _cloudAnchorStatus = "ERROR:$errorMessage";
        _cloudAnchorSubStatus = "";
      });
    }
    // Handle frame post data
    else if (message.startsWith('FRAME_POST_DATA:')) {
      try {
        final jsonData =
            message.toString().substring('FRAME_POST_DATA:'.length);
        print('Received anchor data from Unity: $jsonData');

        setState(() {
          _anchorDataReceived = true;
        });

        final unityJson = jsonDecode(jsonData);
        final latitude = unityJson['latitude'] as double;
        final longitude = unityJson['longitude'] as double;
        print('[LOGS] Latitude: $latitude, Longitude: $longitude');

        // Validate anchor placement
        final anchorRepository = ref.read(anchorRepositoryProvider);
        final validationResponse = await anchorRepository
            .validateAnchorPlacement(latitude, longitude, 10.0);

        if (!validationResponse.isSuccess) {
          setState(() {
            _isPosting = false;
          });

          if (mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => PlacementErrorWidget(
                errorMessage: validationResponse.message,
                username: widget.username,
                onTryAgain: () {
                  Navigator.pop(context);
                },
              ),
            );
          }
          return;
        }

        // Save anchor using repository
        try {
          final anchorRepository = ref.read(anchorRepositoryProvider);
          final response = await anchorRepository.saveAnchor(
              jsonData, widget.pieceData, widget.username);

          if (!response.isSuccess) {
            setState(() {
              _anchorError = response.message;
              _isPosting = false;
            });
            showError(response.message);
            return;
          }

          setState(() {
            _anchorSuccessfullySaved = true;
          });
        } catch (e) {
          print('Using fallback anchor creation method: $e');
          final newAnchor = await createNewAnchor(
              jsonData, widget.pieceData, widget.username);
          await sendAnchorToServer(newAnchor);
          setState(() {
            _anchorSuccessfullySaved = true;
          });
        }

        // Update piece status
        var decodedData = jsonDecode(widget.pieceData);
        String pieceId = decodedData['PieceID'];

        try {
          final pieceRepository = ref.read(pieceRepositoryProvider);
          final response =
              await pieceRepository.togglePieceLiveStatus(pieceId, true);

          if (!response.isSuccess) {
            setState(() {
              _anchorError = response.message;
              _isPosting = false;
            });
            showError(response.message);
            return;
          }
        } catch (e) {
          print('Using fallback piece status update method: $e');
          await togglePieceLiveStatus(pieceId, true);
        }

        print('Piece live status updated to TRUE');

        setState(() {
          _isPosting = false;
        });

        // Clean up Unity before navigating
        final sceneManager = ref.read(unitySceneManagerProvider);
        if (sceneManager.isUnityInitialized) {
          try {
            final controller = sceneManager.getController();
            if (controller != null) {
              // Use safe post message instead
              sceneManager.safePostMessage(
                  'GameManager', 'ResetUnityScene', 'reset');
            }
            await Future.delayed(const Duration(milliseconds: 300));
          } catch (e) {
            print(
                '[AR placement] Error during Unity cleanup in post handler: $e');
          }
        }

        // Navigate with success message
        if (mounted) {
          String successMessage = 'Piece successfully posted!';

          if (_geospatialStatus == "SUCCESS") {
            successMessage =
                'Piece successfully posted with geospatial anchor!';
          } else if (_cloudAnchorStatus == "SUCCESS") {
            successMessage = 'Piece successfully posted with cloud anchor!';
          } else if (_cloudAnchorStatus == "TIMEOUT" ||
              _cloudAnchorStatus.startsWith("ERROR")) {
            successMessage = 'Piece posted with GPS location only';
          }

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => UserProfileScreen(
                successMessage: successMessage,
              ),
            ),
          );
        }
      } catch (e) {
        print('Error processing anchor data: $e');
        setState(() {
          _isPosting = false;
          _anchorError = e.toString();
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error posting piece: $e'),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } else if (message == 'PIECE_ANCHORED') {
      print('Piece anchored successfully in Unity');
    }
    // Pass message to scene manager for handling
  }

  void _handleSceneLoaded(SceneLoaded? scene) {
    print('Unity Scene loaded: ${scene?.name}');
    setState(() {
      _currentScene = scene?.name ?? 'not set';
    });

    if (scene != null && scene.name == UnitySceneType.arScene.sceneName) {
      setState(() {
        _isARSceneLoaded = true;
        _isLoading = false;
      });

      Future.delayed(const Duration(milliseconds: 500), () {
        _setPlacementViewType();
      });
    }
  }

  void _switchToARScene() {
    final sceneManager = ref.read(unitySceneManagerProvider);

    if (sceneManager.isUnityInitialized) {
      sceneManager.loadScene(UnitySceneType.arScene);
      print('_switchToARScene called using SceneManager');
    }
  }

  // Updated helper method to get appropriate status message
  String _getPostingStatusMessage() {
    // Prioritize geospatial status if active
    if (_geospatialStatus == "INITIALIZING") {
      return "Initializing location tracking...";
    } else if (_geospatialStatus == "LOCALIZED") {
      return "Creating geospatial anchor...";
    } else if (_geospatialSubStatus.isNotEmpty &&
        _geospatialStatus != "SUCCESS") {
      return _geospatialSubStatus;
    } else if (_geospatialStatus == "SUCCESS") {
      return "Geospatial anchor created!";
    } else if (_geospatialStatus.startsWith("ERROR")) {
      return "Using GPS location instead";
    }

    // Fall back to cloud anchor status
    else if (_cloudAnchorStatus == "STARTED") {
      return "Creating cloud anchor...";
    } else if (_cloudAnchorSubStatus == "SCANNING") {
      return "Scanning for features...";
    } else if (_cloudAnchorSubStatus == "STABILIZING") {
      return "Stabilizing anchor...";
    } else if (_cloudAnchorStatus.startsWith("WAITING")) {
      return "Creating cloud anchor (${_cloudAnchorWaitTime}s)...";
    } else if (_cloudAnchorStatus == "SUCCESS") {
      return "Cloud anchor created!";
    } else if (_cloudAnchorStatus == "TIMEOUT" ||
        _cloudAnchorStatus.startsWith("ERROR")) {
      return "Using GPS location instead";
    } else if (_cloudAnchorStatus == "WARNING") {
      return "Low feature quality - move device to scan more";
    } else if (_anchorDataReceived) {
      return "Saving your piece...";
    } else {
      return "Anchoring your piece in space";
    }
  }

  // Updated helper method to build anchor status widget
  Widget _buildAnchorStatusWidget() {
    // Show geospatial status if active
    if (_geospatialStatus.isNotEmpty && _geospatialStatus != "SUCCESS") {
      return Column(
        children: [
          if (_geospatialStatus == "INITIALIZING")
            const Text(
              "Acquiring precise location using GPS and visual positioning",
              style: TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            )
          else if (_geospatialStatus == "LOCALIZED")
            Column(
              children: [
                Text(
                  "Location accuracy: ${_locationAccuracy.toStringAsFixed(1)}m",
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  "Orientation accuracy: ${_orientationAccuracy.toStringAsFixed(1)}°",
                  style: const TextStyle(fontSize: 12),
                ),
                if (_vpsAvailable)
                  const Text(
                    "Visual positioning system available",
                    style: TextStyle(fontSize: 12, color: Colors.green),
                  ),
              ],
            )
          else if (_geospatialStatus == "NOT_TRACKING")
            const Text(
              "Unable to determine precise location",
              style: TextStyle(fontSize: 12, color: Colors.orange),
            ),
          const SizedBox(height: 8),
          if (_geospatialStatus == "INITIALIZING" ||
              _geospatialStatus == "LOCALIZED")
            const LinearProgressIndicator(),
        ],
      );
    }

    // Fall back to cloud anchor status widget
    else if (_cloudAnchorSubStatus == "SCANNING") {
      return Column(
        children: [
          const Text(
            "Move device to scan environment for best results",
            style: TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: _cloudAnchorSubProgress > 0 && _cloudAnchorSubTotal > 0
                ? _cloudAnchorSubProgress / _cloudAnchorSubTotal
                : null,
          ),
        ],
      );
    } else if (_cloudAnchorSubStatus == "STABILIZING") {
      return Column(
        children: [
          const Text(
            "Hold still while anchor stabilizes",
            style: TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: _cloudAnchorSubProgress > 0 && _cloudAnchorSubTotal > 0
                ? _cloudAnchorSubProgress / _cloudAnchorSubTotal
                : null,
          ),
        ],
      );
    } else if (_cloudAnchorStatus == "STARTED" ||
        _cloudAnchorStatus.startsWith("WAITING")) {
      return Column(
        children: [
          const Text(
            "This will improve accuracy for other users finding your piece",
            style: TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: _cloudAnchorWaitTime / 40,
          ),
        ],
      );
    } else if (_geospatialStatus == "SUCCESS") {
      return const Text(
        "Your piece will be anchored with geospatial precision!",
        style: TextStyle(color: Colors.green, fontSize: 14),
        textAlign: TextAlign.center,
      );
    } else if (_cloudAnchorStatus == "SUCCESS") {
      return const Text(
        "Your piece will be anchored with high precision!",
        style: TextStyle(color: Colors.green, fontSize: 14),
        textAlign: TextAlign.center,
      );
    } else if (_cloudAnchorStatus == "TIMEOUT" ||
        _geospatialStatus.startsWith("ERROR")) {
      return const Text(
        "Anchor timed out, but your piece will still be visible using GPS",
        style: TextStyle(color: Colors.orange, fontSize: 12),
        textAlign: TextAlign.center,
      );
    } else if (_cloudAnchorStatus.startsWith("ERROR")) {
      return const Text(
        "Anchoring not available, but your piece will still be visible using GPS",
        style: TextStyle(color: Colors.orange, fontSize: 12),
        textAlign: TextAlign.center,
      );
    } else if (_cloudAnchorStatus == "WARNING") {
      return const Text(
        "Poor environment features detected. Try moving the device to scan more.",
        style: TextStyle(color: Colors.orange, fontSize: 12),
        textAlign: TextAlign.center,
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        await _cleanupAndNavigate();
      },
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: () async {
                              await _cleanupAndNavigate();
                            },
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    'Frame Loaded: ${_isFrameLoaded ? "Yes" : "No"}'),
                                Text('Current view: $_currentViewType'),
                                Text('Scene: $_currentScene'),
                                if (_geospatialStatus.isNotEmpty)
                                  Text('Geospatial: $_geospatialStatus'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Error message display
                    if (_errorMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          _errorMessage,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),

                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: UnifiedUnityView(
                                  initialScene: UnitySceneType.arScene,
                                  onUnityMessage: _handleUnityMessage,
                                  onUnitySceneLoaded: _handleSceneLoaded,
                                ),
                              ),

                              // Loading overlay
                              if (_isLoading || !_isSceneReady)
                                Container(
                                  color: Colors.white,
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),

                              if (_currentScene != 'frames_ar' && !_isLoading)
                                const Center(
                                  child: Text('Loading AR Scene...'),
                                )
                              else if (!_isARSceneLoaded && !_isLoading)
                                const Center(
                                  child: Text(
                                      'AR Scene not loaded. Please wait or retry.'),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton(
                            onPressed: _isFrameLoaded
                                ? null
                                : () {
                                    final sceneManager =
                                        ref.read(unitySceneManagerProvider);
                                    if (sceneManager.isUnityInitialized) {
                                      final controller =
                                          sceneManager.getController();
                                      if (controller != null) {
                                        controller.postMessage(
                                          'ARManager',
                                          'LoadFrameInAR',
                                          widget.pieceData,
                                        );
                                      }
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                            child: Text(
                              _isFrameLoaded ? 'Frame Loaded' : 'Load Frame',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                          if (_isFrameLoaded)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Column(
                                children: [
                                  const Text(
                                    'Touch and drag the frame to move it',
                                    style: TextStyle(color: Colors.black),
                                  ),
                                  const SizedBox(height: 8),
                                  ElevatedButton(
                                    onPressed: (_isFrameLoaded && !_isPosting)
                                        ? () {
                                            showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return AlertDialog(
                                                  title: const Text(
                                                      'Confirmation'),
                                                  content: const Text(
                                                      'Are you sure you want to post this piece in this location?'),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () {
                                                        Navigator.of(context)
                                                            .pop();
                                                      },
                                                      child: const Text('No'),
                                                    ),
                                                    TextButton(
                                                      onPressed: () async {
                                                        // Close the confirmation dialog
                                                        Navigator.of(context)
                                                            .pop();

                                                        // Start the posting process with state
                                                        setState(() {
                                                          _isPosting = true;
                                                          _anchorDataReceived =
                                                              false;
                                                          _anchorSuccessfullySaved =
                                                              false;
                                                          _anchorError = null;

                                                          // Reset cloud anchor status
                                                          _cloudAnchorStatus =
                                                              "";
                                                          _cloudAnchorWaitTime =
                                                              0;
                                                          _cloudAnchorId = null;
                                                          _cloudAnchorSubStatus =
                                                              "";
                                                          _cloudAnchorSubProgress =
                                                              0;
                                                          _cloudAnchorSubTotal =
                                                              0;

                                                          // Reset geospatial status
                                                          _geospatialStatus =
                                                              "";
                                                          _geospatialSubStatus =
                                                              "";
                                                          _locationAccuracy =
                                                              0.0;
                                                          _orientationAccuracy =
                                                              0.0;
                                                          _vpsAvailable = false;
                                                        });

                                                        // Tell Unity to post the piece using SceneManager
                                                        final sceneManager =
                                                            ref.read(
                                                                unitySceneManagerProvider);
                                                        if (sceneManager
                                                            .isUnityInitialized) {
                                                          final controller =
                                                              sceneManager
                                                                  .getController();
                                                          if (controller !=
                                                              null) {
                                                            //  setAuthToken(); // Ensure auth token is set for iOS
                                                            controller
                                                                .postMessage(
                                                              'ARManager',
                                                              'PostPiece',
                                                              '',
                                                            );
                                                            print(
                                                                'Posting piece data to Unity');
                                                          }
                                                        }

                                                        // Set an extended timeout (60 seconds to allow for geospatial initialization)
                                                        Future.delayed(
                                                            const Duration(
                                                                seconds: 60),
                                                            () {
                                                          if (mounted &&
                                                              _isPosting &&
                                                              !_anchorDataReceived) {
                                                            setState(() {
                                                              _isPosting =
                                                                  false;
                                                              _anchorError =
                                                                  "Posting timed out after 60 seconds";
                                                            });

                                                            ScaffoldMessenger
                                                                    .of(context)
                                                                .showSnackBar(
                                                              const SnackBar(
                                                                content: Text(
                                                                    'Posting timed out. Please try again.'),
                                                                duration:
                                                                    Duration(
                                                                        seconds:
                                                                            3),
                                                              ),
                                                            );
                                                          }
                                                        });
                                                      },
                                                      child: const Text('Yes'),
                                                    ),
                                                  ],
                                                );
                                              },
                                            );
                                          }
                                        : null,
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 24, vertical: 12),
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(2)),
                                      ),
                                    ),
                                    child: Text(
                                      _isPosting
                                          ? 'Posting...'
                                          : 'Post Piece Here',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ElevatedButton(
                              onPressed: () {
                                final sceneManager =
                                    ref.read(unitySceneManagerProvider);
                                if (sceneManager.isUnityInitialized) {
                                  final controller =
                                      sceneManager.getController();
                                  if (controller != null) {
                                    //  setAuthToken(); // Ensure auth token is set for iOS
                                    controller.postMessage(
                                      'ARManager',
                                      'WaitForEarthTracking',
                                      '',
                                    );
                                    print(
                                        '[geo] Wait for Earth tracking Button pressed');
                                  }
                                }
                              },
                              child: const Text('Wait for Earth Tracking'))
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Overlay loading indicator that appears only when _isPosting is true
              if (_isPosting)
                Container(
                  color: Colors.black54,
                  child: Center(
                    child: Card(
                      margin: const EdgeInsets.all(16),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 16),
                            Text(
                              _getPostingStatusMessage(),
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            _buildAnchorStatusWidget(),
                            if (_anchorError != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  'Error: $_anchorError',
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
