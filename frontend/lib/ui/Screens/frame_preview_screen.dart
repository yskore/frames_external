import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_unity_widget/flutter_unity_widget.dart';
import 'package:frames_app/Providers/piece_provider.dart';
import 'package:frames_app/core/mixins/message_mixin.dart';
import 'package:frames_app/core/services/image_flip_service.dart';
import 'package:frames_app/core/services/unity_scene_service.dart';
import 'package:frames_app/providers/user_provider.dart';
import 'package:frames_app/ui/Screens/home_screen.dart';
import 'package:frames_app/ui/Screens/user_profile_screen.dart';
import 'package:frames_app/ui/Widgets/ownership_selection.dart';
import 'package:frames_app/ui/Widgets/unified_unity_view.dart';
import 'package:image_picker/image_picker.dart';

class FramePreviewScreen extends ConsumerStatefulWidget {
  final String frameName;
  final String faceName;
  final String imageUrl;

  const FramePreviewScreen({
    super.key,
    required this.frameName,
    required this.faceName,
    required this.imageUrl,
  });

  @override
  _FramePreviewScreenState createState() => _FramePreviewScreenState();
}

class _FramePreviewScreenState extends ConsumerState<FramePreviewScreen>
    with MessageMixin {
  // State variables
  bool _isLoading = true;
  bool _isClosing = false;
  bool _dataReadyToSend = false;
  String _errorMessage = '';
  String? _preparedJsonMessage;
  String _ownership = '00'; // Default ownership status
  bool _isHidden = false;
  int _showRadius = 0;

  // Image flip tracking
  String _currentImageUrl = '';
  bool _isHorizontalFlipped = false;
  bool _isVerticalFlipped = false;

  // Form-related variables
  final _formKey = GlobalKey<FormState>();
  String _pieceName = '';
  String _description = '';
  File? _image;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _currentImageUrl = widget.imageUrl; // Initialize with original image
    _loadUserData();
    prepareDataForUnity();

    // Load the Unity scene when the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPreviewScene();
    });
  }

  @override
  void dispose() {
    // Clean up temporary flip files when disposing
    ImageFlipService.cleanupTempFiles();
    super.dispose();
  }

  // Handle ownership change
  void _handleOwnershipChanged(String value) {
    setState(() {
      _ownership = value;
    });
  }

  void _handleHidePieceChanged(bool value) {
    setState(() {
      _isHidden = value;
      if (!value) {
        _showRadius = 0; // Reset radius when unhiding
      }
    });
  }

// Add this method to handle radius changes:

  void _handleRadiusChanged(double value) {
    setState(() {
      _showRadius = value.round();
    });
  }

  Future<void> _loadUserData() async {
    try {
      final user = ref.read(userProvider);
      if (user?.username == null) {
        showError('[LOGS] Failed to load user data.');
        setState(() {
          _isLoading = false;
        });
        return;
      }
    } catch (e) {
      showError('[LOGS] Error loading user data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void prepareDataForUnity() {
    try {
      _preparedJsonMessage = jsonEncode({
        'frameName': widget.frameName,
        'faceName': widget.faceName,
        'imageUrl': _currentImageUrl,
      });
      setState(() {
        _dataReadyToSend = true;
      });
      print('Data prepared for Unity: $_preparedJsonMessage');
    } catch (e) {
      setErrorMessage('Error preparing data for Unity: $e');
    }
  }

  // Unity Scene Management with SceneManager
  void _loadPreviewScene() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final sceneManager = ref.read(unitySceneManagerProvider);

      if (sceneManager.isUnityInitialized) {
        // Check if already in preview scene
        if (sceneManager.currentScene != UnitySceneType.previewScene) {
          print('[LOGS] Loading preview scene from SceneManager');

          // Load the preview scene
          final success =
              await sceneManager.loadScene(UnitySceneType.previewScene);

          if (success) {
            setState(() {
              _isLoading = false;
            });

            // Send piece data to Unity after a slight delay
            Future.delayed(const Duration(milliseconds: 500), () {
              // _sendPieceDataToUnity();
            });
          } else {
            setErrorMessage('Failed to load preview scene');
          }
        } else {
          // Already in preview scene, just send piece data
          setState(() {
            _isLoading = false;
          });

          //  _sendPieceDataToUnity();
        }
      } else {
        print(
            '[LOGS] Unity not initialized yet, will wait for UnityWidget creation');
      }
    } catch (e) {
      setErrorMessage('Error loading preview scene: $e');
    }
  }

  void _sendPieceDataToUnity() {
    try {
      final sceneManager = ref.read(unitySceneManagerProvider);

      if (sceneManager.isUnityInitialized) {
        final controller = sceneManager.getController();

        if (controller != null) {
          print('[LOGS] Sending piece data to Unity for piece preview');

          controller.postMessage(
            'GameManager',
            'ReceiveDataFromFlutter',
            _preparedJsonMessage!,
          );

          print('[LOGS] Piece data sent to Unity successfully');
        } else {
          print('[LOGS] Unity controller is null');
        }
      } else {
        print('[LOGS] Unity not initialized yet');
      }
    } catch (e) {
      setErrorMessage('Error sending data to Unity: $e');
    }
  }

  void _sendUnityCommand(String command, [String? message]) {
    try {
      final sceneManager = ref.read(unitySceneManagerProvider);

      if (sceneManager.isUnityInitialized) {
        final controller = sceneManager.getController();

        if (controller != null) {
          if (message != null) {
            controller.postMessage('GameManager', command, message);
          } else {
            controller.postMessage('GameManager', command, '');
          }
          print('[LOGS] Unity command sent: $command');
        }
      }
    } catch (e) {
      setErrorMessage('Error sending Unity command: $e');
    }
  }

  // Image flip methods
  Future<void> _flipHorizontal() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('[FLIPMONITOR] Starting horizontal flip...');
      print('[FLIPMONITOR] Current image URL: $_currentImageUrl');
      print('[FLIPMONITOR] Horizontal flipped state: $_isHorizontalFlipped');

      if (_isHorizontalFlipped) {
        // Unflip - revert to original or vertically flipped version
        if (_isVerticalFlipped) {
          // Keep vertical flip, remove horizontal
          String flippedImageUrl =
              await ImageFlipService.flipVertical(widget.imageUrl);
          _currentImageUrl = flippedImageUrl;
        } else {
          // Revert to completely original
          _currentImageUrl = widget.imageUrl;
        }
        _isHorizontalFlipped = false;
      } else {
        // Flip horizontally
        String flippedImageUrl =
            await ImageFlipService.flipHorizontal(_currentImageUrl);
        _currentImageUrl = flippedImageUrl;
        _isHorizontalFlipped = true;
      }

      print('[FLIPMONITOR] Updated current URL: $_currentImageUrl');
      print('[FLIPMONITOR] Updated horizontal state: $_isHorizontalFlipped');

      // Clear Unity scene and wait for reset confirmation
      _sendUnityCommand('ResetUnityScene');

      print('[FLIPMONITOR] Horizontal flip completed');
    } catch (e) {
      print('[FLIPMONITOR] Error flipping image horizontally: $e');
      setErrorMessage('Error flipping image horizontally: $e');
    }
  }

  Future<void> _flipVertical() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('[FLIPMONITOR] Starting vertical flip...');
      print('[FLIPMONITOR] Current image URL: $_currentImageUrl');
      print('[FLIPMONITOR] Vertical flipped state: $_isVerticalFlipped');

      if (_isVerticalFlipped) {
        // Unflip - revert to original or horizontally flipped version
        if (_isHorizontalFlipped) {
          // Keep horizontal flip, remove vertical
          String flippedImageUrl =
              await ImageFlipService.flipHorizontal(widget.imageUrl);
          _currentImageUrl = flippedImageUrl;
        } else {
          // Revert to completely original
          _currentImageUrl = widget.imageUrl;
        }
        _isVerticalFlipped = false;
      } else {
        // Flip vertically
        String flippedImageUrl =
            await ImageFlipService.flipVertical(_currentImageUrl);
        _currentImageUrl = flippedImageUrl;
        _isVerticalFlipped = true;
      }

      print('[FLIPMONITOR] Updated current URL: $_currentImageUrl');
      print('[FLIPMONITOR] Updated vertical state: $_isVerticalFlipped');

      // Clear Unity scene and wait for reset confirmation
      _sendUnityCommand('ResetUnityScene');

      print('[FLIPMONITOR] Vertical flip completed');
    } catch (e) {
      print('[FLIPMONITOR] Error flipping image vertically: $e');
      setErrorMessage('Error flipping image vertically: $e');
    }
  }

  // Handle Unity messages from UnifiedUnityView
  void _handleUnityMessage(String message) {
    print('Received message from Unity: $message');

    switch (message) {
      case 'TEXTURE_LOADING_STARTED':
        print('${DateTime.now()}: Processing TEXTURE_LOADING_STARTED');
        break;
      case 'TEXTURE_LOADING_COMPLETED':
        print('${DateTime.now()}: Processing TEXTURE_LOADING_COMPLETED');
        setState(() {
          _isLoading = false;
        });
        break;
      case 'TEXTURE_LOADING_FAILED':
        print('${DateTime.now()}: Processing TEXTURE_LOADING_FAILED');
        setErrorMessage('Failed to load texture');
        break;
      case 'SCENE_RESET_COMPLETE':
        print('[FLIPMONITOR] Scene reset complete - sending new piece data');
        prepareDataForUnity();
        _sendPieceDataToUnity();
        break;
      case 'SCENE_RESET_FAILED':
        print('[FLIPMONITOR] Scene reset failed');
        setErrorMessage('Failed to reset Unity scene');
        break;
      default:
        if (message.startsWith('ACTIVE_SCENE:')) {
          String activeScene = message.split(':')[1];
          if (activeScene == 'frames_test') {
            setState(() {
              _isLoading = false;
            });
            print('Current scene loaded: $activeScene');

            // Send piece data after scene is loaded
            // _sendPieceDataToUnity();
          } else {
            print(
                'Wrong scene loaded: $activeScene - switching to frames_test');
            _switchToFramesTestScene();
          }
        } else if (message == 'SCENE_SWITCHED') {
          setState(() {
            _isLoading = false;
          });
          print('Scene switched to frames_test');

          // Send piece data after scene is switched
          //_sendPieceDataToUnity();
        }
    }
  }

  void _switchToFramesTestScene() {
    final sceneManager = ref.read(unitySceneManagerProvider);

    if (sceneManager.isUnityInitialized) {
      sceneManager.loadScene(UnitySceneType.previewScene);
      print('_switchToFramesTestScene called using SceneManager');
    }
  }

  Future getImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      } else {
        print('No image selected.');
      }
    });
  }

  Future<void> _handleClosing() async {
    if (_isClosing) return; // Prevent multiple closing attempts

    setState(() {
      _isClosing = true;
    });

    try {
      // Clean up temporary files
      await ImageFlipService.cleanupTempFiles();

      // Use the SceneManager to safely dispose the controller
      final sceneManager = ref.read(unitySceneManagerProvider);
      if (sceneManager.isUnityInitialized) {
        await sceneManager.safeDisposeController();
      }

      // Short delay to ensure everything is cleaned up
      await Future.delayed(const Duration(milliseconds: 100));

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const HomeScreen(),
          ),
        );
      }
    } catch (e) {
      print('Error during closing: $e');
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  void setErrorMessage(String message) {
    setState(() {
      _errorMessage = message;
      _isLoading = false;
    });
    print('Error: $message');
  }

  Widget _buildHiddenPieceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),

        // Hide piece toggle
        Row(
          children: [
            Switch(
              value: _isHidden,
              onChanged: _handleHidePieceChanged,
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Hide Piece',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),

        if (_isHidden) ...[
          const SizedBox(height: 8),
          const Text(
            'Hidden pieces can only be previewed by you. Others can see the location but only view the piece in AR mode.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 16),

          // Show radius section
          const Text(
            'Location Display (0-500 meters)',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _showRadius.toDouble(),
                  min: 0,
                  max: 500,
                  divisions: 10,
                  label: _showRadius == 0
                      ? 'Exact location'
                      : '${_showRadius}m radius',
                  onChanged: _handleRadiusChanged,
                ),
              ),
              SizedBox(
                width: 100,
                child: Text(
                  _showRadius == 0
                      ? 'Exact location'
                      : '${_showRadius}m radius',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),
          Text(
            _showRadius == 0
                ? 'Others will see the exact location on the map'
                : 'Others will see a ${_showRadius}m radius area instead of the exact location',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ],
    );
  }

  Future<bool> _savePiece() async {
    final user = ref.read(userProvider);
    final username = user?.username;

    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      if (_image == null) {
        showError('Please select a display picture');
        return false;
      }

      // Create File from current image URL (which might be flipped)
      File imageToUpload;
      if (_currentImageUrl.startsWith('file://')) {
        // It's a local file path (flipped image)
        String filePath = _currentImageUrl.substring(7);
        imageToUpload = File(filePath);
      } else {
        // It's still the original URL, use the display picture instead
        imageToUpload = _image!;
      }

      final piecePro = ref.read(pieceProvider.notifier);
      final res = await piecePro.createPiece(
        pieceTitle: _pieceName,
        faceName: widget.faceName,
        frameName: widget.frameName,
        pieceDescription: _description,
        pieceLocation: "no location",
        pieceForSale: false,
        piecePrice: 0,
        pieceImage: imageToUpload,
        pieceOwner: username!,
        ownership: _ownership,
        isHidden: _isHidden,
        showRadius: _showRadius,
      );

      if (!res) return false;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Piece saved successfully!')),
      );

      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);

    return PopScope(
      canPop: false, // Prevent automatic popping
      onPopInvoked: (didPop) async {
        if (didPop) return;
        await _handleClosing();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Frame Preview'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _handleClosing,
          ),
        ),
        body: Column(
          children: [
            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.red),
                ),
              ),

            // Unity View
            SizedBox(
              height: 300, // Fixed height for Unity view
              child: Stack(
                children: [
                  // Using UnifiedUnityView here
                  UnifiedUnityView(
                    initialScene: UnitySceneType.previewScene,
                    onUnityMessage: _handleUnityMessage,
                    onUnitySceneLoaded: (scene) {
                      if (scene?.name ==
                          UnitySceneType.previewScene.sceneName) {
                        setState(() {
                          _isLoading = false;
                        });

                        // Send piece data once scene is loaded
                        _sendPieceDataToUnity();
                      }
                    },
                  ),

                  // Loading overlay
                  if (_isLoading)
                    Container(
                      color: Colors.white,
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                ],
              ),
            ),

            // Image flip controls
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _flipHorizontal,
                    icon: const Icon(Icons.flip),
                    label: Text(_isHorizontalFlipped ? 'Unflip H' : 'Flip H'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _isHorizontalFlipped ? Colors.blue : null,
                      foregroundColor:
                          _isHorizontalFlipped ? Colors.white : null,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _flipVertical,
                    icon: const Icon(Icons.flip_camera_android),
                    label: Text(_isVerticalFlipped ? 'Unflip V' : 'Flip V'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isVerticalFlipped ? Colors.blue : null,
                      foregroundColor: _isVerticalFlipped ? Colors.white : null,
                    ),
                  ),
                ],
              ),
            ),

            // Form section
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          decoration:
                              const InputDecoration(labelText: 'Piece Name'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a name for the piece';
                            }
                            return null;
                          },
                          onSaved: (value) {
                            _pieceName = value!;
                          },
                        ),
                        TextFormField(
                          decoration:
                              const InputDecoration(labelText: 'Description'),
                          maxLines: 3,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a description';
                            }
                            return null;
                          },
                          onSaved: (value) {
                            _description = value!;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Ownership Selection Widget
                        OwnershipSelectionWidget(
                          initialValue: _ownership,
                          onChanged: _handleOwnershipChanged,
                          isEditing: true,
                        ),
                        _buildHiddenPieceSection(),
                        const SizedBox(height: 20),

                        const Text('Piece Display Picture'),
                        const SizedBox(height: 10),
                        _image == null
                            ? const Text('No image selected.')
                            : Image.file(_image!),
                        ElevatedButton(
                          onPressed: getImage,
                          child: const Text('Pick Image'),
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: ElevatedButton(
                            onPressed: () async {
                              setState(() {
                                _isLoading = true;
                              });

                              final success = await _savePiece();

                              if (success) {
                                print(
                                    "[TEST] Success: Piece saved successfully");
                                // First safely dispose the Unity controller
                                final sceneManager =
                                    ref.read(unitySceneManagerProvider);
                                if (sceneManager.isUnityInitialized) {
                                  print(
                                      "[TEST] isUnityInitialized = True: Disposing Unity controller");
                                  try {
                                    await sceneManager.safeDisposeController();
                                  } catch (e) {
                                    print(
                                        'Error disposing Unity controller: $e');
                                  }
                                }

                                // Clean up temporary files
                                await ImageFlipService.cleanupTempFiles();

                                // Navigate to profile after Unity is fully disposed
                                if (mounted) {
                                  print(
                                      "[TEST] mounted so Navigating to UserProfileScreen");
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const UserProfileScreen(),
                                    ),
                                  );
                                } else {
                                  print(
                                      "[TEST] Not mounted so not navigating to UserProfileScreen");
                                }
                              } else {
                                setState(() {
                                  _isLoading = false;
                                });
                              }
                            },
                            child: const Text('Save & Continue'),
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
    );
  }
}
