import 'package:flutter/material.dart';
import 'package:flutter_unity_widget/flutter_unity_widget.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frames_app/Providers/error_provider.dart';
import 'package:frames_app/Functions/piece_anchoring.dart';
import 'package:frames_app/Functions/piece_loading.dart' hide LocationService;
import 'package:frames_app/core/services/location.dart';
import 'package:frames_app/core/repositories/anchor_repository.dart';

class UnityARView extends ConsumerStatefulWidget {
  const UnityARView({super.key});

  @override
  _UnityARViewState createState() => _UnityARViewState();
}

class _UnityARViewState extends ConsumerState<UnityARView> {
  UnityWidgetController? _unityWidgetController;
  bool _isARSceneLoaded = false;
  bool _isLoading = true;
  bool _hasCameraPermission = false;
  bool _hasLocationPermission = false;
  String _arSessionState = "Unknown";
  bool _surfaceDetected = false;
  bool _isFrameLoaded = false;
  Timer? _pieceLoadingTimer;
  double _gpsAccuracy = 0.0;
  late AnchorService _anchorService;

  // Calibration states
  bool _isCalibrating = false;
  int _calibrationProgress = 0;
  String _calibrationStatus = '';
  bool _calibrationCompleted = false;
  String _currentViewType = 'not set';
  
  // New variables to manage calibration UX
  bool _userHasCompletedCalibration = false;
  bool _showCalibrationWarning = false;
  String _calibrationQuality = 'Unknown';

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _anchorService = AnchorService();
    _startLocationUpdates();
  }
  
  Future<void> _requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      Permission.location,
    ].request();

    setState(() {
      _hasCameraPermission = statuses[Permission.camera]?.isGranted ?? false;
      _hasLocationPermission = statuses[Permission.location]?.isGranted ?? false;
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
    if (_isCalibrating) {
      print('Calibration already in progress');
      return;
    }

    setState(() {
      _isCalibrating = true;
      _calibrationProgress = 0;
      _calibrationStatus = 'Initializing GPS calibration...';
      _showCalibrationWarning = false; // Hide warning when starting calibration
    });

    Future.delayed(Duration(seconds: 5), () {
      if (_isCalibrating) {
        _showCalibrationTimeoutDialog('Unknown');
      }
    });

    _unityWidgetController?.postMessage(
      'LocationManager',
      'StartCalibration',
      '',
    );
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
      if (!_userHasCompletedCalibration) {
        _showCalibrationTimeoutDialog(status);
      } else {
        // Just update the status without showing dialog
        setState(() {
          _isCalibrating = false;
          _showCalibrationWarning = true;
        });
      }
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
          
          // Only show warning if quality is poor
          _showCalibrationWarning = 
              status.contains('Poor') || status.contains('Fair');
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
            _showCalibrationWarning = true;
          });
          
          // Only show the dialog if user hasn't completed calibration yet
          if (!_userHasCompletedCalibration) {
            _showCalibrationFailedDialog();
          }
          break;

        case 'CALIBRATION_PREREQUISITES_MISSING':
          setState(() {
            _isCalibrating = false;
            _calibrationStatus = 'Prerequisites not met';
            _showCalibrationWarning = true;
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
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showCalibrationFailedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Calibration Failed'),
          content: Text(
            'GPS calibration failed. This might be due to poor GPS signal or movement during calibration. Would you like to try again?'
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Try Again'),
              onPressed: () {
                Navigator.of(context).pop();
                _startCalibration();
              },
            ),
            TextButton(
              child: Text('Proceed Anyway'),
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _userHasCompletedCalibration = true;
                  _calibrationCompleted = true;
                  _showCalibrationWarning = true;
                });
              },
            ),
          ],
        );
      },
    );
  }

  void _showCalibrationTimeoutDialog(String status) {
    // Don't show dialog if user has already dealt with calibration
    if (_userHasCompletedCalibration) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('GPS Calibration Timeout'),
          content: Text(
            'Current calibration quality: $status\n\n' +
            'Would you like to retry calibration or proceed with current readings?'
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Retry'),
              onPressed: () {
                Navigator.of(context).pop();
                _startCalibration();
              },
            ),
            TextButton(
              child: Text('Proceed Anyway'),
              onPressed: () async {
                setState(() {
                  _isLoading = true;  // Show loading
                  _userHasCompletedCalibration = true;
                  _calibrationCompleted = true;
                  _showCalibrationWarning = status.contains('Poor') || status.contains('Fair');
                });
                Navigator.of(context).pop();
                await _unityWidgetController?.postMessage(
                  'LocationManager',
                  'ForceCalibrationCompletion',
                  ''
                );
                setState(() => _isLoading = false);  // Hide loading
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
            'Please enable them in your device settings.'
          ),
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
      color: Colors.black12,  // More transparent
      child: Center(
        child: Container(
          padding: EdgeInsets.all(20),
          margin: EdgeInsets.symmetric(horizontal: 40),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.7),  // Semi-transparent white
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

  Widget _buildCalibrationWarningBanner() {
    if (!_showCalibrationWarning) return SizedBox.shrink();
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: Colors.amber.withOpacity(0.7),
      child: Row(
        children: [
          Icon(Icons.warning, color: Colors.deepOrange),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'GPS calibration quality: $_calibrationQuality',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          TextButton(
            onPressed: () => _startCalibration(),
            child: Text('RECALIBRATE'),
            style: TextButton.styleFrom(
              backgroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          )
        ],
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
              child: UnityWidget(
                onUnityCreated: (controller) {
                  onUnityCreated(controller);
                  // Only start calibration automatically if user hasn't completed it
                  if (!_userHasCompletedCalibration) {
                    _startCalibration();
                  }
                },
                onUnityMessage: (message) {
                  onUnityMessage(message);
                  _handleCalibrationMessage(message.toString());
                },
                onUnitySceneLoaded: onUnitySceneLoaded,
                fullscreen: false,
                useAndroidViewSurface: true,
              ),
            )
          else
            Center(child: Text('Camera and Location permission is required for AR.')),

          if (_isLoading)
            Center(child: CircularProgressIndicator())
          else if (!_isARSceneLoaded)
            Center(child: Text('AR Scene not loaded. Please wait or retry.')),

          // Calibration warning banner at top
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: _buildCalibrationWarningBanner(),
            ),
          ),

          // Status panel
          Positioned(
            top: _showCalibrationWarning ? 80 : 40, // Adjust position if warning banner is showing
            left: 20,
            child: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Frame Loaded: ${_isFrameLoaded ? "Yes" : "No"}', 
                       style: TextStyle(color: Colors.white, fontSize: 12)),
                  Text('GPS Calibrated: ${_calibrationCompleted ? "Yes" : "No"}', 
                       style: TextStyle(color: Colors.white, fontSize: 12)),
                  Text('GPS Accuracy: ${_gpsAccuracy.toStringAsFixed(1)}%', 
                       style: TextStyle(color: Colors.white, fontSize: 12)),
                  Text('View type: $_currentViewType', 
                       style: TextStyle(color: Colors.white, fontSize: 12)),
                ],
              ),
            ),
          ),

          // Calibration overlay - only show during calibration process
          if (_isCalibrating && !_userHasCompletedCalibration)
            _buildCalibrationOverlay(),

          // Load pieces button at bottom
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Show recalibrate button if needed but not already calibrating
                if (_userHasCompletedCalibration && !_isCalibrating && _gpsAccuracy < 60)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.gps_fixed),
                      label: Text('Recalibrate GPS'),
                      onPressed: _startCalibration,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                      ),
                    ),
                  ),
                
                // Main Load Pieces button
                ElevatedButton(
                  onPressed: (_calibrationCompleted || _userHasCompletedCalibration) ? 
                    () {
                      _loadNearbyPiecesEnhanced();
                      print("Load Pieces button pressed (using EnhancedPieceLoader)");
                    } : null,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Load Pieces', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void onUnityCreated(controller) {
    print('Unity Controller created');
    _unityWidgetController = controller;
    
    if (_hasCameraPermission) {
      loadARScene();
    } else {
      print('Camera permission not granted');
    }
  }

  void onUnityMessage(message) {
    print('Unity message: ${message.toString()}');
    if (message.toString() == 'AR_COMPONENTS_INITIALIZED') {
      setState(() {
        _isARSceneLoaded = true;
        _isLoading = false;
      });
    } else if (message.toString().startsWith('AR_SESSION_STATE:')) {
      setState(() {
        _arSessionState = message.toString().split(':')[1];
      });
    } else if (message.toString() == 'AR_SURFACE_DETECTED') {
      setState(() {
        _surfaceDetected = true;
      });
    } else if (message.toString() == 'AR_INITIALIZATION_FAILED') {
      print('AR initialization failed');
    } else if (message.toString() == 'FRAME_LOADED') {
      setState(() {
        _isFrameLoaded = true;
      });
    } else if (message.toString().startsWith('CURRENT_VIEW_TYPE:')) {
      String viewType = message.toString().split(':')[1];
      print('Current AR View Type: $viewType');
      setState(() {
        _currentViewType = viewType;  // Store it in state if needed
      });
    }
  }

  void onUnitySceneLoaded(SceneLoaded? scene) {
    print('Unity Scene loaded: ${scene?.name}');
  }

  void loadARScene() {
    print('Loading AR Scene');
    _unityWidgetController?.postMessage(
      'SceneLoader',
      'LoadSceneByName',
      'Scenes/frames_ar'
    );

    print('Loading AR Scene - General View');
    _unityWidgetController?.postMessage(
      'ARManager',
      'SetARViewType',
      'general'
    );
    
    // Add delay before checking view type
    Future.delayed(Duration(milliseconds: 500), () {
      print('Checking current view type');
      checkCurrentViewType();
    });
  }

  void checkCurrentViewType() {
    _unityWidgetController?.postMessage(
      'ARManager',
      'GetCurrentViewType',
      ''
    );
  }

  void _loadNearbyPiecesEnhanced() async {
    try {
      final location = await LocationService.getCurrentLocation();
      if (location != null) {
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
          'pieces': anchorResponse.data!.map((anchor) => {
            'pieceid': anchor.pieceId,           // Change pieceId to pieceid
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
          }).toList(),
        };
        
        final jsonData = jsonEncode(piecesData);
        print('[LOGS] Cloud Sending formatted data to EnhancedPieceLoader');
        
        // Send properly formatted data to EnhancedPieceLoader
        _unityWidgetController?.postMessage(
          'EnhancedPieceLoader',
          'LoadNearbyPieces',
          jsonData,
        );
        
        setState(() {
          _isLoading = false;
        });
      }
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

  @override
  void dispose() {
    _pieceLoadingTimer?.cancel();
    super.dispose();
  }
}
