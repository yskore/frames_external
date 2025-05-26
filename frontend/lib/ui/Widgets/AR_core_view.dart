import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:flutter_unity_widget/flutter_unity_widget.dart';
import 'package:frames_app/Providers/piece_provider.dart';
import 'package:frames_app/core/repositories/anchor_repository.dart';
import 'package:frames_app/core/repositories/piece_repository.dart';
import 'package:frames_app/core/services/location.dart';
import 'package:frames_app/core/services/unity_scene_service.dart';
import 'package:frames_app/models/anchor_model.dart';
import 'package:frames_app/ui/Widgets/enhanced_piece_details_sheet.dart';
import 'package:frames_app/ui/Widgets/piece_interaction_widget.dart';
import 'package:permission_handler/permission_handler.dart';

// A Custom implementation of the UnifiedUnityView with improved sizing
class SizedUnifiedUnityView extends ConsumerStatefulWidget {
  final UnitySceneType initialScene;
  final Function(String)? onUnityMessage;
  // final Function(SceneLoaded?)? onUnitySceneLoaded;

  const SizedUnifiedUnityView({
    super.key,
    required this.initialScene,
    this.onUnityMessage,
    // this.onUnitySceneLoaded,
  });

  @override
  ConsumerState<SizedUnifiedUnityView> createState() =>
      _SizedUnifiedUnityViewState();
}

class _SizedUnifiedUnityViewState extends ConsumerState<SizedUnifiedUnityView> {
  final bool _isLoading = true;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // This positions the Unity widget to leave space for UI elements
        // ClipRect(
        //   child: Align(
        //     alignment: Alignment.center,
        //     child: UnityWidget(
        //       onUnityCreated: (controller) {
        //         final manager = ref.read(unitySceneManagerProvider);
        //         manager.setController(controller);

        //         setState(() {
        //           _isLoading = false;
        //         });

        //         // Load the initial scene
        //         manager.loadScene(widget.initialScene).then((success) {
        //           if (success) {
        //             print('Initial scene loaded successfully: ${widget.initialScene.sceneName}');
        //           } else {
        //             print('Failed to load initial scene: ${widget.initialScene.sceneName}');
        //           }
        //         });
        //       },
        //       onUnityMessage: (message) {
        //         if (widget.onUnityMessage != null) {
        //           widget.onUnityMessage!(message.toString());
        //         }
        //       },
        //       onUnitySceneLoaded: widget.onUnitySceneLoaded,
        //       fullscreen: false,
        //       useAndroidViewSurface: true,
        //     ),
        //   ),
        // ),
        if (_isLoading)
          const Center(
            child: CircularProgressIndicator(),
          ),
      ],
    );
  }
}

class UnityARView extends ConsumerStatefulWidget {
  const UnityARView({super.key});

  @override
  UnityARViewState createState() => UnityARViewState();
}

class UnityARViewState extends ConsumerState<UnityARView>
    with WidgetsBindingObserver {
  // State flags
  bool _isLoading = true;
  bool _hasCameraPermission = false;
  bool _hasLocationPermission = false;
  bool _isARSceneLoaded = false;
  String _arSessionState = "Unknown";
  bool _surfaceDetected = false;
  bool _isFrameLoaded = false;
  double _gpsAccuracy = 0.0;
  Timer? _pieceLoadingTimer;

  // Calibration states
  bool _isCalibrating = false;
  int _calibrationProgress = 0;
  String _calibrationStatus = '';
  bool _calibrationCompleted = false;
  String _currentViewType = 'not set';

  // Calibration UX variables
  bool _userHasCompletedCalibration = false;
  String _calibrationQuality = 'Unknown';

  // Piece selection variables
  String? _selectedPieceData;

  // Impression tracking
  final Set<String> _recentlyImpressedPieces = {};
  final Map<String, Timer> _impressionTimers = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _requestPermissions();
    _startLocationUpdates();

    // Auto-set user has completed calibration to true
    // This will allow loading pieces without waiting for calibration
    _userHasCompletedCalibration = true;
    _calibrationCompleted = true;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      // When app comes to foreground, ensure we're on the AR scene
      final sceneManager = ref.read(unitySceneManagerProvider);
      if (sceneManager.isUnityInitialized) {
        if (sceneManager.currentScene != UnitySceneType.arScene) {
          // Load AR scene if we're not already on it
          sceneManager.loadScene(UnitySceneType.arScene);
        }

        // Small delay before setting view type
        Future.delayed(const Duration(milliseconds: 500), () {
          sceneManager.setARViewType('general');
        });
      }
    }
  }

  Future<void> _requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      Permission.location,
    ].request();

    setState(() {
      _hasCameraPermission = statuses[Permission.camera]?.isGranted ?? false;
      _hasLocationPermission =
          statuses[Permission.location]?.isGranted ?? false;
    });

    if (!_hasCameraPermission || !_hasLocationPermission) {
      _showPermissionDeniedDialog();
    }
  }

  Future<void> _startLocationUpdates() async {
    _pieceLoadingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      // Optionally refresh nearby pieces periodically
      // _loadNearbyPiecesEnhanced();
    });
  }

  void _startCalibration() {
    // Set calibration state
    setState(() {
      _isCalibrating = true;
      _calibrationProgress = 0;
      _calibrationStatus = 'Initializing GPS calibration...';
    });

    // Get the Unity controller and send calibration message
    final sceneManager = ref.read(unitySceneManagerProvider);
    if (sceneManager.isUnityInitialized) {
      final controller = sceneManager.getController();
      if (controller != null) {
        controller.postMessage(
          'LocationManager',
          'StartCalibration',
          '',
        );
      }
    }
  }

  void _handleUnityMessage(String message) {
    print('Unity message received: $message');

    // Handle standard AR session messages
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

      // If we receive a view type that isn't 'general', set it to general
      if (viewType != 'general') {
        final sceneManager = ref.read(unitySceneManagerProvider);
        if (sceneManager.isUnityInitialized) {
          sceneManager.setARViewType('general');
        }
      }
    }
    // Handle piece selection
    else if (message.startsWith('PIECE_SELECTED:')) {
      final pieceData = message.toString().substring('PIECE_SELECTED:'.length);
      print('Piece selected: $pieceData');

      if (mounted) {
        setState(() {
          _selectedPieceData = pieceData;
        });
        _showPieceInfo();
      }
    }
    // Handle piece impression tracking
    else if (message.startsWith('PIECE_LOADED:')) {
      final pieceId = message.toString().substring('PIECE_LOADED:'.length);
      print('[IMP] Piece loaded: $pieceId');

      // Track and increment impressions when a piece is loaded
      _trackImpression(pieceId);
    }
    // Handle calibration-related messages
    else {
      _handleCalibrationMessage(message);
    }
  }

  void _handleCalibrationMessage(String message) {
    print('Calibration message received: $message');

    if (message.isEmpty) {
      print('Received empty calibration message');
      return;
    }

    if (message.startsWith('CALIBRATION_PROGRESS:')) {
      final parts = message.split(':');
      if (parts.length >= 5) {
        final current = int.parse(parts[1]);
        final total = int.parse(parts[2]);
        final confidence = double.parse(parts[3].replaceAll('%', ''));
        final status = parts[4];

        setState(() {
          _calibrationProgress = ((current / total) * 100).round();
          _calibrationStatus = '$status (${confidence.toStringAsFixed(1)}%)';
          _gpsAccuracy = confidence;
          _calibrationQuality = status;
        });
      }
    } else if (message.startsWith('CALIBRATION_TIME_ELAPSED:')) {
      final status = message.contains(':') ? message.split(':')[1] : 'Unknown';
      _calibrationQuality = status;
      setState(() {
        _isCalibrating = false;
      });
    } else if (message.startsWith('CALIBRATION_COMPLETED:')) {
      final parts = message.split(':');
      if (parts.length >= 3) {
        final confidence = double.parse(parts[1]);
        final status = parts[2];
        setState(() {
          _isCalibrating = false;
          _calibrationCompleted = true;
          _calibrationStatus = status;
          _gpsAccuracy = confidence;
          _calibrationQuality = status;
          _userHasCompletedCalibration = true;
        });
      } else {
        // Handle legacy format or simple completion message
        setState(() {
          _isCalibrating = false;
          _calibrationCompleted = true;
          _calibrationStatus = 'Calibration completed';
          _userHasCompletedCalibration = true;
        });
      }
    } else {
      switch (message) {
        case 'CALIBRATION_STARTED':
          setState(() {
            _calibrationStatus = 'Starting calibration...';
            _isCalibrating = true;
            _calibrationProgress = 0;
          });
          break;

        case 'CALIBRATION_FAILED':
          setState(() {
            _isCalibrating = false;
            _calibrationStatus = 'Calibration failed';
            // Even if calibration fails, allow the user to continue
            _userHasCompletedCalibration = true;
            _calibrationCompleted = true;
          });
          break;

        case 'CALIBRATION_PREREQUISITES_MISSING':
          setState(() {
            _isCalibrating = false;
            _calibrationStatus = 'Prerequisites not met';

            // Even if prerequisites are missing, allow the user to continue
            _userHasCompletedCalibration = true;
            _calibrationCompleted = true;
          });
          break;

        case 'PIECES_LOADED_SUMMARY:VPS=0,GPS=0':
          _showPiecesLoadedSummary(0, 0);
          break;

        default:
          if (message.startsWith('PIECES_LOADED_SUMMARY:')) {
            // Parse and display loading results
            String summary = message.split(':')[1];
            List<String> counts = summary.split(',');
            int vpsCount = 0;
            int gpsCount = 0;

            for (var count in counts) {
              if (count.startsWith('VPS=')) {
                vpsCount = int.parse(count.substring(4));
              } else if (count.startsWith('GPS=')) {
                gpsCount = int.parse(count.substring(4));
              }
            }

            _showPiecesLoadedSummary(vpsCount, gpsCount);
          } else {
            print('Unhandled calibration message: $message');
          }
      }
    }
  }

  void _showPiecesLoadedSummary(int vpsCount, int gpsCount) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Pieces loaded: $vpsCount via VPS, $gpsCount via GPS',
          textAlign: TextAlign.center,
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Permissions Required'),
          content: const Text(
              'Camera and location permissions are required to use AR features. '
              'Please enable them in your device settings.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Open Settings'),
              onPressed: () {
                openAppSettings();
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // This is a key change: We're using a Container to position the Unity view
            // specifically to make room for UI elements
            // if (_hasCameraPermission && _hasLocationPermission)
            // Positioned.fill(
            //   // Leave space at bottom for buttons
            //   bottom: 80,
            //   child: SizedUnifiedUnityView(
            //     initialScene: UnitySceneType.arScene,
            //     onUnityMessage: _handleUnityMessage,
            //     onUnitySceneLoaded: (scene) {
            //       // When AR scene is loaded, ensure we're in general view type
            //       if (scene != null && scene.name == UnitySceneType.arScene.sceneName) {
            //         final manager = ref.read(unitySceneManagerProvider);
            //         Future.delayed(Duration(milliseconds: 500), () {
            //           manager.setARViewType('general');

            //           // Request current view type to update state
            //           Future.delayed(Duration(milliseconds: 200), () {
            //             manager.requestCurrentViewType();
            //           });
            //         });
            //       }
            //     },
            //   ),
            // )
            // else
            const Center(
                child:
                    Text('Camera and Location permission is required for AR.')),

            // Semi-transparent layer over Unity to enable interaction with Flutter widgets
            // This is a critical part of the solution
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  color: Colors.transparent,
                ),
              ),
            ),

            // Loading indicator
            if (_isLoading) const Center(child: CircularProgressIndicator()),

            // Status panel - now should be visible above Unity
            Positioned(
              top: 20,
              left: 20,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black
                      .withOpacity(0.7), // More opaque to ensure visibility
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Frame Loaded: ${_isFrameLoaded ? "Yes" : "No"}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                    Text(
                        'GPS Calibrated: ${_calibrationCompleted ? "Yes" : "No"}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                    Text('GPS Accuracy: ${_gpsAccuracy.toStringAsFixed(1)}%',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                    Text('View type: $_currentViewType',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),

            // Load pieces button at bottom - elevated above Unity view
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ElevatedButton(
                  onPressed: () {
                    _loadNearbyPiecesEnhanced();
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    elevation: 8, // Higher elevation to stand out
                    shadowColor: Colors.black.withOpacity(0.5),
                  ),
                  child: const Text('Load Pieces',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _loadNearbyPiecesEnhanced() async {
    try {
      final location = await LocationService.getCurrentLocation();
      setState(() {
        _isLoading = true;
      });

      print('Location Retrieved: ${location.latitude}, ${location.longitude}');
      print('Fetching Nearby Anchors');
      final anchorRepository = ref.read(anchorRepositoryProvider);

      final anchorResponse = await anchorRepository.fetchNearbyAnchors(100.0);

      if (anchorResponse.error != null || anchorResponse.data == null) {
        throw Exception(anchorResponse.error ?? "Failed to fetch anchors");
      }

      // Convert anchors to the exact format expected by EnhancedPieceLoader
      final piecesData = {
        'pieces': anchorResponse.data!
            .map((anchor) => {
                  'pieceid': anchor.pieceId, // Change pieceId to pieceid
                  'anchorId': anchor.anchorId,
                  'frameName': anchor.frameName,
                  'faceName': anchor.faceName,
                  'imageUrl': anchor.imageUrl,
                  'latitude': anchor.location.coordinates[1],
                  'longitude': anchor.location.coordinates[0],
                  'arPosition': anchor.arPosition.toJson(),
                  'arRotation': anchor.arRotation.toJson(),
                  'localScale': anchor.localScale.toJson(),
                  'heightAboveCamera': anchor.heightAboveCamera,
                  'cloudAnchorId': anchor.cloudAnchorId ?? '',
                })
            .toList(),
      };

      final jsonData = jsonEncode(piecesData);
      print('[LOGS] Cloud Sending formatted data to EnhancedPieceLoader');

      // Send properly formatted data to EnhancedPieceLoader using SceneManager
      final sceneManager = ref.read(unitySceneManagerProvider);
      if (sceneManager.isUnityInitialized) {
        final controller = sceneManager.getController();
        if (controller != null) {
          controller.postMessage(
            'EnhancedPieceLoader',
            'LoadNearbyPieces',
            jsonData,
          );
        }
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      setState(() {
        _isLoading = false;
      });
      print('Error loading nearby pieces: $e');
      print('Stack trace: $stackTrace');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load pieces: ${e.toString()}')),
      );
    }
  }

  void _showPieceInfo() {
    if (_selectedPieceData == null) return;

    // Store the data locally so it can't be changed during the modal display
    final pieceData = _selectedPieceData!;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: true, // Ensure it's dismissible
      enableDrag: true, // Allow dragging to dismiss
      builder: (context) => PieceInteractionWidget(
        pieceData: pieceData,
        onClose: () {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        },
        onViewDetails: () {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
          _viewDetailedPieceInfo();
        },
      ),
    ).then((_) {
      // Use a guard to ensure we only reset if still mounted
      if (mounted) {
        setState(() {
          // Only reset if the current selectedPieceData matches what was shown
          // This prevents issues if multiple sheets were shown rapidly
          if (_selectedPieceData == pieceData) {
            _selectedPieceData = null;
            print('TEST: Selected piece data reset after modal closed');
          }
        });
      }
    }).catchError((error) {
      // Add error handling just in case
      print('Error with modal bottom sheet: $error');
      if (mounted) {
        setState(() {
          _selectedPieceData = null;
          print('TEST: Selected piece data reset due to error');
        });
      }
    });
  }

  void _viewDetailedPieceInfo() async {
    try {
      if (_selectedPieceData == null) return;
      final pieceJson = jsonDecode(_selectedPieceData!);
      final pieceId = pieceJson['pieceid'];

      if (pieceId != null) {
        setState(() {
          _isLoading = true;
        });

        // Run these two requests in parallel for efficiency
        final piecesFuture =
            ref.read(pieceProvider.notifier).getPieceDetails(pieceId);
        final anchorFuture =
            ref.read(anchorRepositoryProvider).getAnchorByPieceId(pieceId);

        // Wait for both to complete
        final results = await Future.wait([piecesFuture, anchorFuture]);
        final pieceDetails = results[0];
        final anchorResponse =
            results[1] as ({String? error, AnchorModel? data});

        setState(() {
          _isLoading = false;
        });

        if (pieceDetails != null && mounted) {
          print('TEST: Passing piece details to sheet: $pieceDetails');

          // Create the expected structure for the details sheet
          final formattedDetails = {
            'piece': pieceDetails, // Wrap the piece details in a 'piece' object
            'anchor': anchorResponse.data != null
                ? {
                    'expireTime':
                        anchorResponse.data!.expireTime?.toIso8601String(),
                    'cloudAnchorId': anchorResponse.data!.cloudAnchorId
                  }
                : null
          };

          // Show enhanced bottom sheet with the complete piece details
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            isScrollControlled: true,
            builder: (context) => EnhancedPieceDetailsSheet(
              arPieceData: pieceJson,
              databaseDetails: formattedDetails, // Pass the formatted data
            ),
          );
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Could not retrieve piece details')),
            );
          }
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error fetching piece details: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _trackImpression(String pieceId) {
    // Check if we've already counted this piece recently
    print('[IMP] Track impressions called for piece: $pieceId');
    if (!_recentlyImpressedPieces.contains(pieceId)) {
      // Record the impression
      ref.read(pieceRepositoryProvider).incrementImpressions(pieceId);

      // Add to recently impressed set
      _recentlyImpressedPieces.add(pieceId);

      // Set a timer to remove from the set after 5 minutes
      _impressionTimers[pieceId] = Timer(const Duration(minutes: 5), () {
        _recentlyImpressedPieces.remove(pieceId);
        _impressionTimers.remove(pieceId);
      });
    }
  }

  @override
  void dispose() {
    _impressionTimers.forEach((_, timer) => timer.cancel());
    _impressionTimers.clear();
    _pieceLoadingTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
