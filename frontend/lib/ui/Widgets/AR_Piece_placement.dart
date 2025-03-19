import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frames_app/Providers/error_provider.dart';
// import 'package:flutter_unity_widget/flutter_unity_widget.dart';
import 'package:frames_app/ui/Screens/user_profile_screen.dart';
import 'package:frames_app/core/repositories/anchor_repository.dart';
import 'package:frames_app/core/repositories/piece_repository.dart';
import 'package:permission_handler/permission_handler.dart';

class UnityARViewPlacement extends ConsumerStatefulWidget {
  final String pieceData;
  final String username;
  const UnityARViewPlacement(
      {super.key, required this.pieceData, required this.username});
  @override
  UnityARViewPlacementState createState() => UnityARViewPlacementState();
}

class UnityARViewPlacementState extends ConsumerState<UnityARViewPlacement> {
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
          builder: (context) => const UserProfileScreen(),
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
                          Text('Curent view: $_currentViewType'),
                        ],
                      ),
                    ),
                  ],
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
                        if (_hasCameraPermission)
                          const Positioned.fill(
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
                          const Center(
                              child: Text(
                                  'Camera permission is required for AR.')),
                        if (_isLoading)
                          const Center(child: CircularProgressIndicator())
                        else if (!_isARSceneLoaded)
                          const Center(
                              child: Text(
                                  'AR Scene not loaded. Please wait or retry.')),
                      ],
                    ),
                  ),
                ),
              ),
              if (_isARSceneLoaded)
                Padding(
                  padding: const EdgeInsets.all(16),
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
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: const Text('Confirmation'),
                                        content: const Text(
                                            'Are you sure you want to post this piece in this location?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                            child: const Text('No'),
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

                                              final pieceRepository = ref.read(
                                                  pieceRepositoryProvider);
                                              final response =
                                                  await pieceRepository
                                                      .togglePieceLiveStatus(
                                                          pieceId, true);

                                              if (!response.isSuccess) {
                                                ref
                                                    .read(
                                                        errorProvider.notifier)
                                                    .setError(response.message);
                                                return;
                                              }

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

                                              if (mounted && context.mounted) {
                                                Navigator.pushReplacement(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        const UserProfileScreen(
                                                      successMessage:
                                                          'Piece Successfully Posted!',
                                                    ),
                                                  ),
                                                );
                                              }
                                            },
                                            child: const Text('Yes'),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 12),
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(2)),
                                  ),
                                ),
                                child: const Text(
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

      final anchorRepository = ref.read(anchorRepositoryProvider);
      final response = await anchorRepository.saveAnchor(
          jsonData, widget.pieceData, widget.username);

      if (!response.isSuccess) {
        ref.read(errorProvider.notifier).setError(response.message);
        return;
      }

      return;
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
    Future.delayed(const Duration(milliseconds: 1500), () {
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
