import 'dart:async';

import 'package:flutter/material.dart';
import 'package:frames_app/Functions/piece_loading.dart';
// import 'package:flutter_unity_widget/flutter_unity_widget.dart';
import 'package:permission_handler/permission_handler.dart';

class UnityARView extends StatefulWidget {
  @override
  _UnityARViewState createState() => _UnityARViewState();
}

class _UnityARViewState extends State<UnityARView> {
  // UnityWidgetController? _unityWidgetController;
  bool _isARSceneLoaded = false;
  bool _isLoading = true;
  bool _hasCameraPermission = false;
  bool _hasLocationPermission = false;
  String _arSessionState = "Unknown";
  bool _surfaceDetected = false;
  bool _isFrameLoaded = false;
  late AnchorService _anchorService;
  late LocationService _locationService;
  Timer? _pieceLoadingTimer;
  double _gpsAccuracy = 0.0;

  // New calibration states
  bool _isCalibrating = false;
  int _calibrationProgress = 0;
  String _calibrationStatus = '';
  bool _calibrationCompleted = false;
  String _currentViewType = 'not set';

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _anchorService = AnchorService();
    _locationService = LocationService();
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
    _pieceLoadingTimer = Timer.periodic(Duration(seconds: 30), (timer) {
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
          title: Text('Calibration Failed'),
          content: Text(
              'GPS calibration failed. This might be due to poor GPS signal or movement during calibration. Would you like to try again?'),
          actions: <Widget>[
            TextButton(
              child: Text('Try Again'),
              onPressed: () {
                Navigator.of(context).pop();
                _startCalibration();
              },
            ),
            TextButton(
              child: Text('Cancel'),
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
          title: Text('Permissions Required'),
          content: Text(
              'Camera and location permissions are required to use AR features. '
              'Please enable them in your device settings.'),
          actions: <Widget>[
            TextButton(
              child: Text('Open Settings'),
              onPressed: () {
                openAppSettings();
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Cancel'),
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
          padding: EdgeInsets.all(20),
          margin: EdgeInsets.symmetric(horizontal: 40),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.7), // Semi-transparent white
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                value: _calibrationProgress / 100,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
              SizedBox(height: 20),
              Text(
                _calibrationStatus,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10),
              Text(
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
            Opacity(
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
            Center(
                child:
                    Text('Camera and Location permission is required for AR.')),
          if (_isLoading)
            Center(child: CircularProgressIndicator())
          else if (!_isARSceneLoaded)
            Center(child: Text('AR Scene not loaded. Please wait or retry.')),
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
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: Text('Load Pieces', style: TextStyle(fontSize: 16)),
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
    try {
      final location = await _locationService.getCurrentLocation();
      if (location != null) {
        print(
            'Location Retrieved: ${location.latitude}, ${location.longitude}');
        print('Fetching Nearby Anchors');
        final anchors = await _anchorService.fetchNearbyAnchors(
          location.latitude,
          location.longitude,
          100.0,
        );

        // Validate each anchor's data
        for (var anchor in anchors) {
          validateAnchorData(anchor);
        }

        print('Sending ${anchors.length} Anchors to Unity');
        // await _anchorService.sendAnchorsToUnity(_unityWidgetController!, anchors);
      }
    } catch (e, stackTrace) {
      print('Error loading nearby pieces: $e');
      print('Stack trace: $stackTrace');
    }
  }

  @override
  void dispose() {
    _pieceLoadingTimer?.cancel();
    super.dispose();
  }
}
