import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frames_app/ui/Screens/user_profile_screen.dart';
import 'package:frames_app/Functions/piece_anchoring.dart';
import 'package:frames_app/Functions/toggle_live_status.dart';
import 'package:frames_app/ui/Widgets/placementErrorWidget.dart';
import 'package:frames_app/ui/Widgets/unified_unity_view.dart';
import 'package:frames_app/utils/permissions_utils.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:frames_app/Providers/error_provider.dart';
import 'package:frames_app/core/repositories/anchor_repository.dart';
import 'package:frames_app/core/repositories/piece_repository.dart';
import 'package:frames_app/core/services/unity_scene_service.dart';
import 'package:flutter_unity_widget/flutter_unity_widget.dart';

class UnityARViewPlacement extends ConsumerStatefulWidget {
  final String pieceData;
  final String username;

  const UnityARViewPlacement({
    Key? key,
    required this.pieceData,
    required this.username,
  }) : super(key: key);

  @override
  UnityARViewPlacementState createState() => UnityARViewPlacementState();
}

class UnityARViewPlacementState extends ConsumerState<UnityARViewPlacement> {
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
  bool _hasPermissions = true;
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

  @override
  void initState() {
    super.initState();
    //_checkPermissionsAndProceed();

    // Load the Unity AR scene when widget is built - similar to FramePreviewScreen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadARScene();
    });
  }

  // Unity Scene Management with SceneManager - similar to FramePreviewScreen
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
        print('[LOGS] Unity not initialized yet, will wait for UnityWidget creation');
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

  Future<void> _checkPermissionsAndProceed() async {
    // Quick check - no dialog needed if already granted
    if (await PermissionsUtils.hasRequiredPermissions()) {
      // Permissions are good
    } else {
      // This should rarely happen if HomeScreen worked properly
      _handleMissingPermissions();
    }
  }

  void _handleMissingPermissions() {
    // Show error or redirect back to home
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Permissions required. Please restart the app.')),
    );
    Navigator.pop(context);
  }

  // Method for unified cleanup and navigation
  Future<void> _cleanupAndNavigate() async {
    final sceneManager = ref.read(unitySceneManagerProvider);

    try {
      if (sceneManager.isUnityInitialized) {
        await sceneManager.safeDisposeController();
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const UserProfileScreen(),
          ),
        );
      }
    } catch (e) {
      print('Error during navigation: $e');
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
    // Handle scene messages - similar to FramePreviewScreen
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

        // Set placement view type after scene is confirmed loaded
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

      // Set placement view type after scene switch
      _setPlacementViewType();
    }
    // Handle cloud anchor warnings
    else if (message.startsWith('CLOUD_ANCHOR_WARNING:')) {
      final warningMessage = message.split(':')[1];
      print('Cloud anchor warning: $warningMessage');

      setState(() {
        _cloudAnchorStatus = "WARNING";
      });
    }
    // Handle scanning progress
    else if (message.startsWith('CLOUD_ANCHOR_SCANNING:')) {
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
    }
    // Handle stabilizing progress
    else if (message.startsWith('CLOUD_ANCHOR_STATUS:STABILIZING:')) {
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
    }
    // Other cloud anchor status updates
    else if (message.startsWith('CLOUD_ANCHOR_STATUS:')) {
      final parts = message.split(':');
      final status = parts[1];

      setState(() {
        _cloudAnchorStatus = status;

        // Reset substatus when main status changes
        if (status != "SCANNING" && status != "STABILIZING") {
          _cloudAnchorSubStatus = "";
        }

        if (status == "WAITING" && parts.length > 2) {
          _cloudAnchorWaitTime = int.tryParse(parts[2]) ?? 0;
        } else if (status == "SUCCESS" && parts.length > 2) {
          _cloudAnchorId = parts[2];
        }
      });
    }
    // Handle cloud anchor errors
    else if (message.startsWith('CLOUD_ANCHOR_ERROR:')) {
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
        // Extract the JSON data from the message
        final jsonData = message.toString().substring('FRAME_POST_DATA:'.length);
        print('Received anchor data from Unity: $jsonData');

        setState(() {
          _anchorDataReceived = true;
        });

        final unityJson = jsonDecode(jsonData);
        final latitude = unityJson['latitude'] as double;
        print('[LOGS]Latitude: $latitude');
        final longitude = unityJson['longitude'] as double;
        print('[LOGS]Longitude: $longitude');

        // Validate anchor placement
        final anchorRepository = ref.read(anchorRepositoryProvider);
        final validationResponse = await anchorRepository.validateAnchorPlacement(
            latitude, longitude, 10.0);

        if (!validationResponse.isSuccess) {
          setState(() {
            _isPosting = false;
          });

          // Show the placement error dialog
          if (mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => PlacementErrorWidget(
                errorMessage: validationResponse.message,
                username: widget.username,
                onTryAgain: () {
                  Navigator.pop(context); // Close the dialog
                },
              ),
            );
          }
          return;
        }

        // Try to use provider repository if available, otherwise fall back to direct functions
        try {
          final anchorRepository = ref.read(anchorRepositoryProvider);
          final response = await anchorRepository.saveAnchor(
              jsonData, widget.pieceData, widget.username);

          if (!response.isSuccess) {
            setState(() {
              _anchorError = response.message;
              _isPosting = false;
            });
            ref.read(errorProvider.notifier).setError(response.message);
            return;
          }

          setState(() {
            _anchorSuccessfullySaved = true;
          });
        } catch (e) {
          // Fall back to direct function calls if provider is not available
          print('Using fallback anchor creation method: $e');
          final newAnchor = await createNewAnchor(jsonData, widget.pieceData, widget.username);
          print('New anchor created: $newAnchor');
          await sendAnchorToServer(newAnchor);
          print('Anchor successfully sent to server');

          setState(() {
            _anchorSuccessfullySaved = true;
          });
        }

        // Update piece status - try to use repository first
        var decodedData = jsonDecode(widget.pieceData);
        String pieceId = decodedData['PieceID'];

        try {
          final pieceRepository = ref.read(pieceRepositoryProvider);
          final response = await pieceRepository.togglePieceLiveStatus(pieceId, true);

          if (!response.isSuccess) {
            setState(() {
              _anchorError = response.message;
              _isPosting = false;
            });
            ref.read(errorProvider.notifier).setError(response.message);
            return;
          }
        } catch (e) {
          // Fall back to direct function call
          print('Using fallback piece status update method: $e');
          await togglePieceLiveStatus(pieceId, true);
        }

        print('Piece live status updated to TRUE');

        // Hide the loading overlay
        setState(() {
          _isPosting = false;
        });

        // Clean up Unity before navigating
        final sceneManager = ref.read(unitySceneManagerProvider);
        if (sceneManager.isUnityInitialized) {
          final controller = sceneManager.getController();
          if (controller != null) {
            await controller.postMessage(
                'GameManager',
                'ResetUnityScene',
                'reset'
            );
          }
          await Future.delayed(const Duration(milliseconds: 500));
        }

        // Navigate with success message that includes cloud anchor status
        if (mounted) {
          String successMessage = 'Piece successfully posted!';

          if (_cloudAnchorStatus == "SUCCESS") {
            successMessage = 'Piece successfully posted with cloud anchor!';
          } else if (_cloudAnchorStatus == "TIMEOUT" || _cloudAnchorStatus.startsWith("ERROR")) {
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

        // Hide the loading overlay on error too
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
  }

  void _handleSceneLoaded(SceneLoaded? scene) {
    print('Unity Scene loaded: ${scene?.name}');
    setState(() {
      _currentScene = scene?.name ?? 'not set';
    });
    print('Current scene set to: $_currentScene');

    if (scene != null && scene.name == UnitySceneType.arScene.sceneName) {
      setState(() {
        _isARSceneLoaded = true;
        _isLoading = false;
      });

      // Set view type to placement
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
    if (_cloudAnchorStatus == "STARTED") {
      return "Creating cloud anchor...";
    } else if (_cloudAnchorSubStatus == "SCANNING") {
      return "Scanning for features...";
    } else if (_cloudAnchorSubStatus == "STABILIZING") {
      return "Stabilizing anchor...";
    } else if (_cloudAnchorStatus.startsWith("WAITING")) {
      return "Creating cloud anchor (${_cloudAnchorWaitTime}s)...";
    } else if (_cloudAnchorStatus == "SUCCESS") {
      return "Cloud anchor created!";
    } else if (_cloudAnchorStatus == "TIMEOUT" || _cloudAnchorStatus.startsWith("ERROR")) {
      return "Using GPS location instead";
    } else if (_cloudAnchorStatus == "WARNING") {
      return "Low feature quality - move device to scan more";
    } else if (_anchorDataReceived) {
      return "Saving your piece...";
    } else {
      return "Anchoring your piece in space";
    }
  }

  // Updated helper method to build cloud anchor status widget
  Widget _buildCloudAnchorStatusWidget() {
    if (_cloudAnchorSubStatus == "SCANNING") {
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
                : null, // Indeterminate if no progress values
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
    } else if (_cloudAnchorStatus == "STARTED" || _cloudAnchorStatus.startsWith("WAITING")) {
      return Column(
        children: [
          const Text(
            "This will improve accuracy for other users finding your piece",
            style: TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: _cloudAnchorWaitTime / 40, // 40 seconds is the max wait time
          ),
        ],
      );
    } else if (_cloudAnchorStatus == "SUCCESS") {
      return const Text(
        "Your piece will be anchored with high precision!",
        style: TextStyle(color: Colors.green, fontSize: 14),
        textAlign: TextAlign.center,
      );
    } else if (_cloudAnchorStatus == "TIMEOUT") {
      return const Text(
        "Cloud anchor timed out, but your piece will still be visible using GPS",
        style: TextStyle(color: Colors.orange, fontSize: 12),
        textAlign: TextAlign.center,
      );
    } else if (_cloudAnchorStatus.startsWith("ERROR")) {
      return const Text(
        "Cloud anchoring not available, but your piece will still be visible using GPS",
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
                                Text('Frame Loaded: ${_isFrameLoaded ? "Yes" : "No"}'),
                                Text('Current view: $_currentViewType'),
                                Text('Scene: $_currentScene'),
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
                                  child: Text('AR Scene not loaded. Please wait or retry.'),
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
                                    final sceneManager = ref.read(unitySceneManagerProvider);
                                    if (sceneManager.isUnityInitialized) {
                                      final controller = sceneManager.getController();
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
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
                                                  title: const Text('Confirmation'),
                                                  content: const Text('Are you sure you want to post this piece in this location?'),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () {
                                                        Navigator.of(context).pop();
                                                      },
                                                      child: const Text('No'),
                                                    ),
                                                    TextButton(
                                                      onPressed: () async {
                                                        // Close the confirmation dialog
                                                        Navigator.of(context).pop();

                                                        // Start the posting process with state
                                                        setState(() {
                                                          _isPosting = true;
                                                          _anchorDataReceived = false;
                                                          _anchorSuccessfullySaved = false;
                                                          _anchorError = null;
                                                          _cloudAnchorStatus = "";
                                                          _cloudAnchorWaitTime = 0;
                                                          _cloudAnchorId = null;
                                                          _cloudAnchorSubStatus = "";
                                                          _cloudAnchorSubProgress = 0;
                                                          _cloudAnchorSubTotal = 0;
                                                        });

                                                        // Tell Unity to post the piece using SceneManager
                                                        final sceneManager = ref.read(unitySceneManagerProvider);
                                                        if (sceneManager.isUnityInitialized) {
                                                          final controller = sceneManager.getController();
                                                          if (controller != null) {
                                                            controller.postMessage(
                                                              'ARManager',
                                                              'PostPiece',
                                                              '',
                                                            );
                                                            print('Posting piece data to Unity');
                                                          }
                                                        }

                                                        // Set an extended timeout (40 seconds to match Unity's timeout)
                                                        Future.delayed(const Duration(seconds: 40), () {
                                                          if (mounted && _isPosting && !_anchorDataReceived) {
                                                            setState(() {
                                                              _isPosting = false;
                                                              _anchorError = "Posting timed out after 40 seconds";
                                                            });

                                                            ScaffoldMessenger.of(context).showSnackBar(
                                                              const SnackBar(
                                                                content: Text('Posting timed out. Please try again.'),
                                                                duration: Duration(seconds: 3),
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
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.all(Radius.circular(2)),
                                      ),
                                    ),
                                    child: Text(
                                      _isPosting ? 'Posting...' : 'Post Piece Here',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            _buildCloudAnchorStatusWidget(),
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
