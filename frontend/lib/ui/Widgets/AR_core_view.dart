import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frames_app/core/repositories/anchor_repository.dart';
import 'package:frames_app/providers/error_provider.dart';
// import 'package:flutter_unity_widget/flutter_unity_widget.dart';
import 'package:permission_handler/permission_handler.dart';

class UnityARView extends ConsumerStatefulWidget {
  const UnityARView({super.key});

  @override
  _UnityARViewState createState() => _UnityARViewState();
}

class _UnityARViewState extends ConsumerState<UnityARView> {
  // UnityWidgetController? _unityWidgetController;
  final bool _isARSceneLoaded = false;
  final bool _isLoading = true;
  bool _hasCameraPermission = false;
  bool _hasLocationPermission = false;
  final String _arSessionState = "Unknown";
  final bool _surfaceDetected = false;
  final bool _isFrameLoaded = false;
  Timer? _pieceLoadingTimer;
  double _gpsAccuracy = 0.0;

  // New calibration states
  bool _isCalibrating = false;
  int _calibrationProgress = 0;
  String _calibrationStatus = '';
  bool _calibrationCompleted = false;
  final String _currentViewType = 'not set';

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _startLocationUpdates();
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
      // _loadNearbyPieces();
    });
  }

  void _startCalibration() {
    setState(() {
      _isCalibrating = true;
      _calibrationProgress = 0;
      _calibrationStatus = 'Initializing GPS calibration...';
    });

    // _unityWidgetController?.postMessage(
    //   'LocationManager',
    //   'StartCalibration',
    //   '',
    // );
  }

  void _handleCalibrationMessage(String message) {
    print('Calibration message received: $message');

    if (message.startsWith('CALIBRATION_PROGRESS:')) {
      final parts = message.split(':')[1].split('/');
      final current = int.parse(parts[0]);
      final total = int.parse(parts[1]);

      setState(() {
        _calibrationProgress = ((current / total) * 100).round();
        _calibrationStatus = 'Collecting GPS samples... $_calibrationProgress%';
      });
    } else {
      switch (message) {
        case 'CALIBRATION_STARTED':
          setState(() {
            _calibrationStatus = 'Starting calibration...';
          });
          break;
        case 'CALIBRATION_COMPLETED':
          setState(() {
            _isCalibrating = false;
            _calibrationCompleted = true;
            _calibrationStatus = 'Calibration completed';
          });
          break;
        case 'CALIBRATION_FAILED':
          setState(() {
            _isCalibrating = false;
            _calibrationStatus = 'Calibration failed';
          });
          _showCalibrationFailedDialog();
          break;
      }
    }
    if (message.startsWith('CALIBRATION_COMPLETED:')) {
      final accuracy = double.parse(message.split(':')[1]);
      setState(() {
        _isCalibrating = false;
        _calibrationCompleted = true;
        _calibrationStatus = 'Calibration completed';
        _gpsAccuracy = accuracy;
      });
    }
  }

  void _showCalibrationFailedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Calibration Failed'),
          content: const Text(
              'GPS calibration failed. This might be due to poor GPS signal or movement during calibration. Would you like to try again?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Try Again'),
              onPressed: () {
                Navigator.of(context).pop();
                _startCalibration();
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

  Widget _buildCalibrationOverlay() {
    return Container(
      color: Colors.black12, // More transparent
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.symmetric(horizontal: 40),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.7), // Semi-transparent white
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                value: _calibrationProgress / 100,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
              const SizedBox(height: 20),
              Text(
                _calibrationStatus,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'Please keep your device steady',
                style: TextStyle(fontSize: 14, color: Colors.black87),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          if (_hasCameraPermission && _hasLocationPermission)
            const Opacity(
                opacity: 1.0,
                child: SizedBox(
                  width: double.infinity,
                  height: double.infinity,
                  child: Center(child: Text('AR Camera View Placeholder')),
                )
                // UnityWidget(
                //   onUnityCreated: (controller) {
                //     onUnityCreated(controller);
                //     // Start calibration after Unity is created
                //     _startCalibration();
                //   },
                //   onUnityMessage: (message) {
                //     onUnityMessage(message);
                //     _handleCalibrationMessage(message.toString());
                //   },
                //   onUnitySceneLoaded: onUnitySceneLoaded,
                //   fullscreen: false,
                //   useAndroidViewSurface: true,
                // ),
                )
          else
            const Center(
                child:
                    Text('Camera and Location permission is required for AR.')),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (!_isARSceneLoaded)
            const Center(
                child: Text('AR Scene not loaded. Please wait or retry.')),
          Positioned(
            top: 40,
            left: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Frame Loaded: ${_isFrameLoaded ? "Yes" : "No"}'),
                Text('GPS Calibrated: ${_calibrationCompleted ? "Yes" : "No"}'),
                Text('GPS Accuracy: ${_gpsAccuracy.toStringAsFixed(2)}m'),
                Text('Current view type: $_currentViewType'),
              ],
            ),
          ),
          if (_isCalibrating) _buildCalibrationOverlay(),
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton(
                onPressed: _calibrationCompleted
                    ? () {
                        _loadNearbyPieces();
                        print("_loadNearbyPieces button pressed");
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child:
                    const Text('Load Pieces', style: TextStyle(fontSize: 16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // void onUnityCreated(controller) {
  //   print('Unity Controller created');
  //   _unityWidgetController = controller;

  //   if (_hasCameraPermission) {
  //     loadARScene();
  //   } else {
  //     print('Camera permission not granted');
  //   }
  // }

  // void onUnityMessage(message) {
  //   print('Unity message: ${message.toString()}');
  //   if (message.toString() == 'AR_COMPONENTS_INITIALIZED') {
  //     setState(() {
  //       _isARSceneLoaded = true;
  //       _isLoading = false;
  //     });
  //   } else if (message.toString().startsWith('AR_SESSION_STATE:')) {
  //     setState(() {
  //       _arSessionState = message.toString().split(':')[1];
  //     });
  //   } else if (message.toString() == 'AR_SURFACE_DETECTED') {
  //     setState(() {
  //       _surfaceDetected = true;
  //     });
  //   } else if (message.toString() == 'AR_INITIALIZATION_FAILED') {
  //     print('AR initialization failed');
  //   } else if (message.toString() == 'FRAME_LOADED') {
  //     setState(() {
  //       _isFrameLoaded = true;
  //     });
  //   } else if (message.toString().startsWith('CURRENT_VIEW_TYPE:')) {
  //   String viewType = message.toString().split(':')[1];
  //   print('Current AR View Type: $viewType');
  //   setState(() {
  //     _currentViewType = viewType;  // Store it in state if needed
  //   });
  // }

  // }

  // void onUnitySceneLoaded(SceneLoaded? scene) {
  //   print('Unity Scene loaded: ${scene?.name}');
  // }

  // void loadARScene() {
  //   print('Loading AR Scene');
  //   _unityWidgetController?.postMessage(
  //     'SceneLoader',
  //     'LoadSceneByName',
  //     'Scenes/frames_ar'
  //   );

  //    print('Loading AR Scene - General View');
  // _unityWidgetController?.postMessage(
  //   'ARManager',
  //   'SetARViewType',
  //   'general'
  // );
  //  // Add delay before checking view type
  // Future.delayed(Duration(milliseconds: 500), () {
  //   print('Checking current view type');
  //   checkCurrentViewType();
  // });
  // }

  // void checkCurrentViewType() {
  // _unityWidgetController?.postMessage(
  //   'ARManager',
  //   'GetCurrentViewType',
  //   ''
  // );
  // }

  void _loadNearbyPieces() async {
    final anchorRepository = ref.read(anchorRepositoryProvider);
    final response = await anchorRepository.fetchNearbyAnchors(
      100.0,
    );

    if (response.error != null) {
      ref.read(errorProvider.notifier).setError(response.error);
      return;
    }

    response.data?.forEach((a) {
      a.validateAnchorData();
    });

    print('Sending ${response.data?.length} Anchors to Unity');
    // await _anchorService.sendAnchorsToUnity(_unityWidgetController!, anchors);
  }

  @override
  void dispose() {
    _pieceLoadingTimer?.cancel();
    super.dispose();
  }
}
