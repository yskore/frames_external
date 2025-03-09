import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:frames_app/Functions/piece_anchoring.dart';
import 'package:frames_app/Functions/toggle_live_status.dart';
// import 'package:flutter_unity_widget/flutter_unity_widget.dart';
import 'package:frames_app/Screens/user_profile_screen.dart';
import 'package:permission_handler/permission_handler.dart';

class UnityARViewPlacement extends StatefulWidget {
  final String pieceData;
  final String username;
  UnityARViewPlacement({required this.pieceData, required this.username});
  @override
  UnityARViewPlacementState createState() => UnityARViewPlacementState();
}

class UnityARViewPlacementState extends State<UnityARViewPlacement> {
  // UnityWidgetController? _unityWidgetController;
  bool _isARSceneLoaded = false;
  bool _isLoading = true;
  bool _hasCameraPermission = false;
  String _arSessionState = "Unknown";
  bool _surfaceDetected = false;
  bool _isFrameLoaded = false;
  String _currentViewType = 'not set';

  @override
  void initState() {
    super.initState();
    _requestCameraPermission();
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    setState(() {
      _hasCameraPermission = status.isGranted;
    });
  }

  // Add this method for unified cleanup
  Future<void> _cleanupAndNavigate() async {
    // if (_unityWidgetController != null) {
    //   await _unityWidgetController?.postMessage(
    //     'GameManager',
    //     'ResetUnityScene',
    //     'reset'
    //   );
    //   await Future.delayed(Duration(milliseconds: 500));
    //   _unityWidgetController?.dispose();
    //   _unityWidgetController = null;
    // }

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => UserProfileScreen(username: widget.username),
        ),
      );
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black),
          ),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back),
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
                          Text('Curent view: $_currentViewType'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  margin: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      children: [
                        if (_hasCameraPermission)
                          Positioned.fill(
                              child: SizedBox(
                            width: double.infinity,
                            height: double.infinity,
                            child: Center(
                                child: Text('AR Camera View Placeholder')),
                          )
                              // UnityWidget(
                              //   onUnityCreated: onUnityCreated,
                              //   onUnityMessage: onUnityMessage,
                              //   onUnitySceneLoaded: onUnitySceneLoaded,
                              //   fullscreen: false,
                              //   useAndroidViewSurface: true,
                              // ),
                              )
                        else
                          Center(
                              child: Text(
                                  'Camera permission is required for AR.')),
                        if (_isLoading)
                          Center(child: CircularProgressIndicator())
                        else if (!_isARSceneLoaded)
                          Center(
                              child: Text(
                                  'AR Scene not loaded. Please wait or retry.')),
                      ],
                    ),
                  ),
                ),
              ),
              if (_isARSceneLoaded)
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton(
                        onPressed: _isFrameLoaded
                            ? null
                            : () {
                                // _unityWidgetController?.postMessage(
                                //   'ARManager',
                                //   'LoadFrameInAR',
                                //   widget.pieceData
                                // );
                                checkCurrentViewType();
                              },
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(
                          _isFrameLoaded ? 'Frame Loaded' : 'Load Frame',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                      if (_isFrameLoaded)
                        Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Column(
                            children: [
                              Text(
                                'Touch and drag the frame to move it',
                                style: TextStyle(color: Colors.black),
                              ),
                              SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: Text('Confirmation'),
                                        content: Text(
                                            'Are you sure you want to post this piece in this location?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                            child: Text('No'),
                                          ),
                                          // Modify the Yes button in the confirmation dialog
                                          TextButton(
                                            onPressed: () async {
                                              // Close the confirmation dialog
                                              //Navigator.of(context).pop();

                                              // Post the piece
                                              // _unityWidgetController?.postMessage(
                                              //   'ARManager',
                                              //   'PostPiece',
                                              //   '',
                                              // );
                                              print(
                                                  'Posting piece data to Unity');

                                              var decodedData =
                                                  jsonDecode(widget.pieceData);
                                              String pieceId =
                                                  decodedData['PieceID'];
                                              await togglePieceLiveStatus(
                                                  pieceId, true);
                                              print(
                                                  'Piece live status updated to TRUE');

                                              // Clean up Unity and navigate with success message
                                              // if (_unityWidgetController != null) {
                                              //   await _unityWidgetController?.postMessage(
                                              //     'GameManager',
                                              //     'ResetUnityScene',
                                              //     'reset'
                                              //   );
                                              //   await Future.delayed(Duration(milliseconds: 500));
                                              //   _unityWidgetController?.dispose();
                                              //   _unityWidgetController = null;
                                              // }

                                              if (mounted) {
                                                Navigator.pushReplacement(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        UserProfileScreen(
                                                      username: widget.username,
                                                      successMessage:
                                                          'Piece Successfully Posted!',
                                                    ),
                                                  ),
                                                );
                                              }
                                            },
                                            child: Text('Yes'),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 12),
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(2)),
                                  ),
                                ),
                                child: Text(
                                  'Post Piece Here',
                                  style: TextStyle(fontSize: 16),
                                ),
                              )
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void onUnityCreated(controller) {
    print('Unity Controller created');
    // _unityWidgetController = controller;

    if (_hasCameraPermission) {
      loadARScene();
    } else {
      print('Camera permission not granted');
    }
  }

  Future<void> onUnityMessage(message) async {
    print('Unity message: ${message.toString()}');
    if (message.toString() == 'AR_COMPONENTS_INITIALIZED') {
      setState(() {
        _isARSceneLoaded = true;
        _isLoading = false;
      });
    } else if (message.toString().startsWith('CURRENT_VIEW_TYPE:')) {
      String viewType = message.toString().split(':')[1];
      print('Current AR View Type: $viewType');
      setState(() {
        _currentViewType = viewType; // Store it in state if needed
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
      // Add new message handler
      setState(() {
        _isFrameLoaded = true;
      });
    } else if (message.toString().startsWith('FRAME_POST_DATA:')) {
      // Handle the position data received from Unity
      final jsonData = message.toString().substring('FRAME_POST_DATA:'.length);
      print('Received post data: $jsonData');
      // Here you would send this data to your MongoDB
      final newanchor =
          await createNewAnchor(jsonData, widget.pieceData, widget.username);
      print('New anchor created & sending to server: $newanchor');
      sendAnchorToServer(newanchor);
    }
  }

  void onUnitySceneLoaded(/*SceneLoaded?*/ scene) {
    print('Unity Scene loaded: ${scene?.name}');
  }

  void loadARScene() {
    print('Loading AR Scene');
    // _unityWidgetController?.postMessage(
    //   'SceneLoader',
    //   'LoadSceneByName',
    //   'Scenes/frames_ar'
    // );

    print('Loading AR Scene - Placement View');
    // _unityWidgetController?.postMessage(
    //   'ARManager',
    //   'SetARViewType',
    //   'placement'
    // );
    // Add delay before checking view type
    Future.delayed(Duration(milliseconds: 1500), () {
      print('Checking current view type');
      checkCurrentViewType();
    });
  }

  void checkCurrentViewType() {
    // _unityWidgetController?.postMessage(
    //   'ARManager',
    //   'GetCurrentViewType',
    //   ''
    // );
  }
}
