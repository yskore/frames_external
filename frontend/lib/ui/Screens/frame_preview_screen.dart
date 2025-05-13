import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frames_app/providers/user_provider.dart';
import 'package:frames_app/ui/Screens/home_screen.dart';
import 'package:frames_app/ui/Screens/user_profile_screen.dart';
import 'package:frames_app/ui/Widgets/ownership_selection.dart';
import 'package:frames_app/ui/Widgets/unified_unity_view.dart';
import 'package:frames_app/core/services/unity_scene_service.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_unity_widget/flutter_unity_widget.dart';
import 'package:image_picker/image_picker.dart';
import 'package:frames_app/Providers/error_provider.dart';
import 'package:frames_app/Providers/piece_provider.dart';

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

class _FramePreviewScreenState extends ConsumerState<FramePreviewScreen> {
  // State variables
  bool _isLoading = true;
  bool _isClosing = false;
  bool _dataReadyToSend = false;
  String _errorMessage = '';
  String? _preparedJsonMessage;
  String _ownership = '00'; // Default ownership status

  // Form-related variables
  final _formKey = GlobalKey<FormState>();
  String _pieceName = '';
  String _description = '';
  File? _image;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserData();
    prepareDataForUnity();
    
    // Load the Unity scene when the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPreviewScene();
    });
  }

  // Handle ownership change
  void _handleOwnershipChanged(String value) {
    setState(() {
      _ownership = value;
    });
  }

  Future<void> _loadUserData() async {
    try {
      final user = ref.read(userProvider);
      if (user?.username == null) {
        ref.read(errorProvider.notifier).setError('[LOGS] Failed to load user data.');
        setState(() {
          _isLoading = false;
        });
        return;
      }
    } catch (e) {
      ref.read(errorProvider.notifier).setError('[LOGS] Error loading user data: $e');
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
        'imageUrl': widget.imageUrl,
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
          final success = await sceneManager.loadScene(UnitySceneType.previewScene);
          
          if (success) {
            setState(() {
              _isLoading = false;
            });
            
            // Send piece data to Unity after a slight delay
            Future.delayed(const Duration(milliseconds: 500), () {
              _sendPieceDataToUnity();
            });
          } else {
            setErrorMessage('Failed to load preview scene');
          }
        } else {
          // Already in preview scene, just send piece data
          setState(() {
            _isLoading = false;
          });
          
          _sendPieceDataToUnity();
        }
      } else {
        print('[LOGS] Unity not initialized yet, will wait for UnityWidget creation');
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
      default:
        if (message.startsWith('ACTIVE_SCENE:')) {
          String activeScene = message.split(':')[1];
          if (activeScene == 'frames_test') {
            setState(() {
              _isLoading = false;
            });
            print('Current scene loaded: $activeScene');
            
            // Send piece data after scene is loaded
            _sendPieceDataToUnity();
          } else {
            print('Wrong scene loaded: $activeScene - switching to frames_test');
            _switchToFramesTestScene();
          }
        } else if (message == 'SCENE_SWITCHED') {
          setState(() {
            _isLoading = false;
          });
          print('Scene switched to frames_test');
          
          // Send piece data after scene is switched
          _sendPieceDataToUnity();
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
    if (_isClosing) return;  // Prevent multiple closing attempts
    
    setState(() {
      _isClosing = true;
    });

    try {
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

  Future<bool> _savePiece() async {
    final user = ref.read(userProvider);
    final username = user?.username;

    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      if (_image == null) {
        ref.read(errorProvider.notifier)
           .setError('Please select a display picture');
        return false;
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
        pieceImage: _image!,
        pieceOwner: username!,
        ownership: _ownership,
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
                      if (scene?.name == UnitySceneType.previewScene.sceneName) {
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
                          decoration: const InputDecoration(labelText: 'Piece Name'),
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
                          decoration: const InputDecoration(labelText: 'Description'),
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
                                // First safely dispose the Unity controller
                                final sceneManager = ref.read(unitySceneManagerProvider);
                                if (sceneManager.isUnityInitialized) {
                                  try {
                                    await sceneManager.safeDisposeController();
                                  } catch (e) {
                                    print('Error disposing Unity controller: $e');
                                  }
                                }
                                
                                // Navigate to profile after Unity is fully disposed
                                if (mounted) {
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (context) => const UserProfileScreen(),
                                    ),
                                  );
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