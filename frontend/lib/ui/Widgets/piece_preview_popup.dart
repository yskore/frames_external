// piece_preview_popup.dart

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frames_app/core/repositories/piece_repository.dart';
import 'package:frames_app/core/services/map.dart';
import 'package:frames_app/models/anchor_model.dart';
import 'package:frames_app/providers/error_provider.dart';
import 'package:frames_app/providers/user_provider.dart';
import 'package:frames_app/ui/Screens/user_profile_screen.dart';
import 'package:frames_app/ui/Widgets/AR_Piece_placement.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

// Create a provider for the piece repository

class PiecePreviewPopup extends ConsumerStatefulWidget {
  String pieceName;
  final String pieceData;
  bool liveStatus;
  final String pieceOwner;
  String? pieceDescription;
  double piecePrice;
  final int pieceLikes;
  bool pieceForSale;
  final DateTime pieceCreationDate;
  final Function onPieceUpdated;

  PiecePreviewPopup({
    super.key,
    required this.pieceName,
    required this.pieceData,
    required this.liveStatus,
    required this.pieceOwner,
    required this.pieceDescription,
    required this.piecePrice,
    required this.pieceLikes,
    required this.pieceForSale,
    required this.pieceCreationDate,
    required this.onPieceUpdated,
  });

  @override
  _PiecePreviewPopupState createState() => _PiecePreviewPopupState();
}

class _PiecePreviewPopupState extends ConsumerState<PiecePreviewPopup> {
  // UnityWidgetController? _unityWidgetController;
  bool _isUnityLoaded = false;
  bool _isUnityInitializing = false;
  bool _isSceneLoading = false;
  String _errorMessage = '';
  bool _isEditing = false;
  bool _isLoading = false;
  bool _isCorrectSceneLoaded = false;
  bool _isSceneReady = false;
  bool _isClosing = false;
  bool isTextureCompleted = false;

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  final List<AnchorModel> _anchors = [];
  bool _isFullScreen = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.pieceName);
    _descriptionController =
        TextEditingController(text: widget.pieceDescription);
    _priceController =
        TextEditingController(text: widget.piecePrice.toString());
  }

  @override
  void dispose() {
    if (!_isClosing) {
      // _unityWidgetController?.dispose();
      // _unityWidgetController = null;
    }
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _initializeUnityScene() async {
    if (_isSceneLoading) return;

    setState(() {
      _isSceneLoading = true;
      _isUnityInitializing = true;
      _isUnityLoaded = false;
      _errorMessage = '';
    });

    // try {
    //   // Reset scene first
    //   _unityWidgetController?.postMessage(
    //       'GameManager', 'ResetUnityScene', 'reset');
    //   print('[Flutter Log] [_initializeUnityScene] Resetting Unity scene');

    //   // Wait for reset
    //   await Future.delayed(Duration(milliseconds: 500));

    //   // Load new scene
    //   _unityWidgetController?.postMessage(
    //       'SceneLoader', 'LoadSceneByName', 'frames_test');

    //   // Wait for scene load
    //   await Future.delayed(Duration(seconds: 1));

    //   setState(() {
    //     _isUnityLoaded = true;
    //   });

    //   // Now send piece data
    //   sendPieceDataToUnity();
    // } catch (e) {
    //   setErrorMessage('Error initializing Unity scene: $e');
    // } finally {
    //   if (mounted) {
    //     setState(() {
    //       _isSceneLoading = false;
    //       _isUnityInitializing = false;
    //     });
    //   }
    // }
  }

  // void onUnityCreated(UnityWidgetController controller) {
  //   print('Unity Widget created - controller: $controller');
  //   _unityWidgetController = controller;
  //   setState(() {
  //     _isClosing = false;
  //   });
  //   _initializeUnityScene();
  // }

  void _onUnityMessage(message) {
    print('Received message from Unity: $message');

    if (message == 'SCENE_SWITCHED') {
      setState(() {
        _setSceneReady();
      });
    }

    switch (message.toString()) {
      case 'TEXTURE_LOADING_STARTED':
        print('${DateTime.now()}: Processing TEXTURE_LOADING_STARTED');

        break;
      case 'TEXTURE_LOADING_COMPLETED':
        print('${DateTime.now()}: Processing TEXTURE_LOADING_COMPLETED');
        setState(() {
          isTextureCompleted = true;
        });

        break;
      case 'TEXTURE_LOADING_FAILED':
        print('${DateTime.now()}: Processing TEXTURE_LOADING_FAILED');

        break;
    }
  }

  void _setSceneReady() {
    setState(() {
      _isLoading = false;
      _isCorrectSceneLoaded = true;
      _isSceneReady = true;
    });
    print('Scene is ready');
  }

  void sendPieceDataToUnity() {
    // if (_unityWidgetController == null) {
    //   setErrorMessage('Unity controller is not initialized');
    //   return;
    // }
    // if (!_isSceneReady) {
    //   print('Scene not ready, delaying sendPieceDataToUnity');
    //   return;
    // }

    // try {
    //   print(
    //       '[TEST] Sending piece data to Unity for piece: ${widget.pieceName}');
    //   print('Data being sent: ${widget.pieceData}');

    //   _unityWidgetController!.postMessage(
    //     'GameManager',
    //     'ReceiveDataFromFlutter',
    //     widget.pieceData,
    //   );
    //   print('Piece data sent to Unity successfully');
    // } catch (e) {
    //   setErrorMessage('Error sending data to Unity: $e');
    // }
  }

  void setErrorMessage(String message) {
    setState(() {
      _errorMessage = message;
      _isUnityInitializing = false;
    });
    print('Error: $message');
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Piece'),
          content: const Text(
              'Are you sure you want to delete this piece? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _deletePiece();
                Navigator.of(context).pop(); // Close dialog
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deletePiece() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final pieceRepository = ref.read(pieceRepositoryProvider);
      final response = await pieceRepository.deletePiece(
          widget.pieceName, widget.pieceOwner);

      if (response.isSuccess && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const UserProfileScreen(
              successMessage: 'Piece deleted successfully',
            ),
          ),
        );
        return;
      }
      ref
          .read(errorProvider.notifier)
          .setError(response.message ?? 'Failed to delete piece');
    } catch (e) {
      ref.read(errorProvider.notifier).setError('Failed to delete piece: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showPieceLocationMap() async {
    var pieceData = jsonDecode(widget.pieceData);
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final pieceRepository = ref.read(pieceRepositoryProvider);
    final anchorResponse =
        await pieceRepository.getAnchorByPieceId(pieceData['PieceID']);

    if (!mounted) return;
    Navigator.pop(context);

    if (anchorResponse.data != null) {
      final anchor = anchorResponse.data!;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) => SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Piece Location',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: LatLng(anchor.location.coordinates[1],
                            anchor.location.coordinates[0]),
                        zoom: 16,
                      ),
                      markers: {
                        Marker(
                          markerId: const MarkerId('piece_location'),
                          position: LatLng(anchor.location.coordinates[1],
                              anchor.location.coordinates[0]),
                          infoWindow: InfoWindow(title: widget.pieceName),
                        )
                      },
                      myLocationEnabled: true,
                      myLocationButtonEnabled: true,
                    ),
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.directions),
                        label: const Text('Get Directions'),
                        onPressed: () {
                          MapService.openGoogleMapsNavigation(
                            anchor.location.coordinates[1],
                            anchor.location.coordinates[0],
                            ref: ref,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
      return;
    }
    ref.read(errorProvider.notifier).setError(anchorResponse.error);
  }

  Future<void> _shareLocation() async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    // Get piece data
    var pieceData = jsonDecode(widget.pieceData);
    final pieceRepository = ref.read(pieceRepositoryProvider);
    final anchorResponse =
        await pieceRepository.getAnchorByPieceId(pieceData['PieceID']);
    if (!mounted) return;

    if (anchorResponse.error != null) {
      ref.read(errorProvider.notifier).setError(anchorResponse.error);
    }

    // Dismiss loading indicator
    Navigator.pop(context);
    final anchor = anchorResponse.data!;

    // Format coordinates for maps
    final lat = anchor.location.coordinates[1];
    final lng = anchor.location.coordinates[0];
    final locationString = '$lat,$lng';

    // Copy to clipboard
    await Clipboard.setData(ClipboardData(text: locationString));

    if (!mounted) return;

    // Show success message with instructions
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Location Copied!'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('The coordinates have been copied to your clipboard.'),
              SizedBox(height: 8),
              Text('To use:'),
              Text('1. Open Google Maps or Apple Maps'),
              Text('2. Paste the coordinates in the search bar'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildEditableInfoRow(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                border: _isEditing ? null : InputBorder.none,
              ),
              readOnly: !_isEditing,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleClosing() async {
    if (_isClosing) return; // Prevent multiple closing attempts

    setState(() {
      _isClosing = true;
    });

    //TODO:temp
    Navigator.of(context).pop();

    // try {
    //   _unityWidgetController?.postMessage(
    //       'GameManager', 'ResetUnityScene', 'reset');

    //   await Future.delayed(const Duration(milliseconds: 500));

    //   if (_unityWidgetController != null) {
    //     _unityWidgetController?.dispose();
    //     _unityWidgetController = null;
    //   }

    //   if (mounted) {
    //     Navigator.of(context).pop();
    //   }
    // } catch (e) {
    //   print('Error during closing: $e');
    //   if (mounted) {
    //     Navigator.of(context).pop();
    //   }
    // }
  }

  void liveStatusChange() {
    if (widget.liveStatus) {
      // Turn offline
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Turn Piece Offline'),
            content: const Text(
                'Are you sure you want to turn this piece offline? Users will not be able to view it and its specific location will be lost.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  setState(() {
                    _isLoading = true;
                  });

                  try {
                    var decodedData = jsonDecode(widget.pieceData);
                    String pieceId = decodedData['PieceID'];

                    final pieceRepository = ref.read(pieceRepositoryProvider);
                    final response = await pieceRepository
                        .togglePieceLiveStatus(pieceId, false);

                    if (response.isSuccess) {
                      setState(() {
                        widget.liveStatus = false;
                      });

                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const UserProfileScreen(
                            successMessage: 'Piece turned offline successfully',
                          ),
                        ),
                      );
                      return;
                    }
                    ref.read(errorProvider.notifier).setError(response.message);
                  } finally {
                    if (mounted) {
                      setState(() {
                        _isLoading = false;
                      });
                    }
                  }
                },
                child: const Text('Turn Offline'),
              ),
            ],
          );
        },
      );
    } else {
      // Turn online
      showPopup(context);
    }
  }

  void showPopup(BuildContext context) {
    final user = ref.read(userProvider);
    final username = user?.username;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Piece Live Placement'),
          content: const Text('Proceed to place this piece live?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () async {
                final String pieceDataToPass = widget.pieceData;
                final String usernameToPass = username!;

                if (mounted) {
                  Navigator.of(context).pop(); // pop alert dialog
                  Navigator.of(context).pop(); // pop piece preview popup

                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => UnityARViewPlacement(
                          pieceData: pieceDataToPass,
                          username: usernameToPass)));
                }
              },
              child: const Text('Proceed'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _savePieceChanges() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final pieceRepository = ref.read(pieceRepositoryProvider);
      final response = await pieceRepository.updatePieceInfo(
        pieceOwner: widget.pieceOwner,
        oldPieceTitle: widget.pieceName,
        newPieceTitle: _nameController.text,
        pieceDescription: _descriptionController.text,
        pieceForSale: widget.pieceForSale,
        piecePrice: double.tryParse(_priceController.text) ?? 0.0,
      );

      if (response.isSuccess) {
        setState(() {
          widget.pieceName = _nameController.text;
          widget.pieceDescription = _descriptionController.text;
          if (widget.pieceForSale) {
            widget.piecePrice =
                double.tryParse(_priceController.text) ?? widget.piecePrice;
          }
          _isEditing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Piece updated successfully')),
        );

        // Refresh user profile data when piece is updated
        await ref.read(userNotifierProvider).refreshUserPieces();

        widget.onPieceUpdated();
      } else {
        throw Exception(response.message ?? 'Failed to update piece');
      }
    } catch (e) {
      // Use error provider instead of direct SnackBar
      ref.read(errorProvider.notifier).setError('Failed to update piece: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        await _handleClosing();
      },
      child: Dialog(
        insetPadding: _isFullScreen
            ? const EdgeInsets.all(8) // Minimal padding in full-screen
            : const EdgeInsets.symmetric(
                horizontal: 40, vertical: 24), // Default padding
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SizedBox(
                width: _isFullScreen
                    ? MediaQuery.of(context).size.width *
                        0.95 // Wider in full-screen
                    : MediaQuery.of(context).size.width * 0.8, // Normal width
                height: _isFullScreen
                    ? MediaQuery.of(context).size.height *
                        0.8 // Taller in full-screen
                    : MediaQuery.of(context).size.height * 0.8,
                child: Column(
                  children: [
                    AppBar(
                      title: Text(widget.pieceName),
                      leading: IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            _handleClosing();
                          }),
                      actions: [
                        IconButton(
                          icon: Icon(_isFullScreen
                              ? Icons.fullscreen_exit
                              : Icons.fullscreen),
                          onPressed: () {
                            setState(() {
                              _isFullScreen = !_isFullScreen;
                            });
                          },
                        ),
                        if (!_isFullScreen) // Only show these buttons when not in full-screen
                          IconButton(
                            icon: Icon(_isEditing ? Icons.save : Icons.edit),
                            onPressed: () {
                              setState(() {
                                if (_isEditing) {
                                  _savePieceChanges();
                                } else {
                                  _isEditing = true;
                                }
                              });
                            },
                          ),
                        if (!_isFullScreen &&
                            _isEditing) // Only show delete in normal mode and edit mode
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: _showDeleteConfirmation,
                          ),
                      ],
                    ),
                    if (_errorMessage.isNotEmpty && !_isFullScreen)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          _errorMessage,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),

                    // Unity Widget container
                    SizedBox(
                      height: _isFullScreen
                          ? MediaQuery.of(context).size.height *
                              0.7 // Larger Unity view in full-screen
                          : MediaQuery.of(context).size.height * 0.3,

                      width: _isFullScreen
                          ? MediaQuery.of(context).size.width *
                              0.95 // Added width constraint
                          : double
                              .infinity, // Take available width in normal mode

                      child: Stack(
                        children: [
                          // UnityWidget(
                          //   onUnityCreated: onUnityCreated,
                          //   onUnityMessage: _onUnityMessage,
                          //   useAndroidViewSurface: true,
                          //   fullscreen: false,
                          // ),
                          // Placeholder instead of Unity Widget
                          Container(
                            color: Colors.grey[300],
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.network(
                                    jsonDecode(widget.pieceData)['imageUrl'] ??
                                        'https://via.placeholder.com/300',
                                    height: _isFullScreen ? 400 : 200,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(
                                          Icons.image_not_supported,
                                          size: 100);
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "${jsonDecode(widget.pieceData)['frameName']} Frame",
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (_isLoading && !isTextureCompleted)
                            Container(
                              color: Colors.white,
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (!_isFullScreen)
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildEditableInfoRow(
                                  'Piece Name', _nameController),
                              _buildInfoRow('Piece Owner', widget.pieceOwner),
                              _buildEditableInfoRow(
                                  'Description', _descriptionController),
                              _buildInfoRow(
                                  'Creation Date',
                                  DateFormat('yyyy-MM-dd')
                                      .format(widget.pieceCreationDate)),
                              _buildInfoRow(
                                  'Likes', widget.pieceLikes.toString()),
                              _buildInfoRow('Live Status',
                                  widget.liveStatus ? 'Live' : 'Not Live'),
                              Row(
                                children: [
                                  const Text('For Sale: ',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  Switch(
                                    value: widget.pieceForSale,
                                    onChanged: _isEditing
                                        ? (value) {
                                            setState(() {
                                              widget.pieceForSale = value;
                                            });
                                          }
                                        : null,
                                  ),
                                ],
                              ),
                              if (widget.pieceForSale)
                                _buildEditableInfoRow(
                                    'Price', _priceController),
                              if (_isEditing)
                                Row(
                                  children: [
                                    ElevatedButton(
                                      onPressed: _savePieceChanges,
                                      child: const Text('Save Changes'),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      onPressed: () {
                                        liveStatusChange();
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: widget.liveStatus
                                            ? Colors.red
                                            : Colors.green,
                                      ),
                                      child: widget.liveStatus
                                          ? const Text('Turn offline')
                                          : const Text('Turn online'),
                                    ),
                                  ],
                                ),
                              if (widget.liveStatus)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          icon: const Icon(Icons.location_on),
                                          label: const Text('Locate'),
                                          onPressed: _showPieceLocationMap,
                                          style: ElevatedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 16, vertical: 8),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          icon:
                                              const Icon(Icons.share_location),
                                          label: const Text('Share Location'),
                                          onPressed: _shareLocation,
                                          style: ElevatedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 16, vertical: 8),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
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
