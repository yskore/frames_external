// piece_preview_popup.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frames_app/core/repositories/anchor_repository.dart';
import 'package:frames_app/core/repositories/piece_repository.dart';
import 'package:frames_app/core/services/unity_scene_service.dart';
import 'package:frames_app/models/piece_model.dart';
import 'package:frames_app/providers/error_provider.dart';
import 'package:frames_app/providers/user_provider.dart';
import 'package:frames_app/ui/Screens/user_profile_screen.dart';
import 'package:frames_app/ui/Widgets/AR_Piece_placement.dart';
import 'package:frames_app/ui/Widgets/piece_edit_section.dart';
import 'package:frames_app/ui/Widgets/piece_info_section.dart';
import 'package:frames_app/ui/Widgets/piece_location_manager.dart';
import 'package:frames_app/ui/Widgets/piece_offer_manager.dart';
import 'package:frames_app/ui/Widgets/piece_unity_viewer.dart';

class PiecePreviewPopup extends ConsumerStatefulWidget {
  final Piece piece;
  final String pieceData;
  final Function onPieceUpdated;
  final bool isReadOnly;

  const PiecePreviewPopup({
    super.key,
    required this.piece,
    required this.pieceData,
    required this.onPieceUpdated,
    this.isReadOnly = false,
  });

  @override
  _PiecePreviewPopupState createState() => _PiecePreviewPopupState();
}

class _PiecePreviewPopupState extends ConsumerState<PiecePreviewPopup> {
  // State variables
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isClosing = false;
  bool _isFullScreen = false;
  String _errorMessage = '';
  String _ownership = '';
  
  // Piece state
  late Piece _piece;
  
  // Anchor details
  DateTime? _anchorExpireTime;
  bool _isLoadingAnchorDetails = false;
  
  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _paymentDetailsController;
  late TextEditingController _currencyController;
  
  // Managers
  late PieceLocationManager _locationManager;
  late PieceOfferManager _offerManager;
  late PieceEditManager _editManager;
  
  // Refresh timer
  Timer? _impressionsRefreshTimer;
  final int _refreshIntervalSeconds = 30;

  @override
  void initState() {
    super.initState();
    
    // Initialize the piece
    _piece = widget.piece;
    
    // Initialize controllers
    _nameController = TextEditingController(text: _piece.pieceTitle);
    _descriptionController = TextEditingController(text: _piece.pieceDescription);
    _priceController = TextEditingController(text: _piece.piecePrice.toString());
    _paymentDetailsController = TextEditingController(text: _piece.paymentDetails ?? '');
    _currencyController = TextEditingController(text: _piece.currency ?? 'USD');
    
    // Initialize ownership
    _ownership = _piece.ownership ?? '00';
    
    // Initialize managers
    _locationManager = PieceLocationManager(
      ref: ref,
      pieceId: jsonDecode(widget.pieceData)['PieceID'],
      pieceTitle: _piece.pieceTitle,
    );
    
    _offerManager = PieceOfferManager(
      piece: _piece,
      paymentDetailsController: _paymentDetailsController,
    );
    
    _editManager = PieceEditManager(
      ref: ref,
      piece: _piece,
      nameController: _nameController,
      descriptionController: _descriptionController,
      priceController: _priceController,
      paymentDetailsController: _paymentDetailsController,
      currencyController: _currencyController,
      ownership: _ownership,
      setLoading: (loading) => setState(() => _isLoading = loading),
      updatePiece: (updatedPiece) => setState(() {
        _piece = updatedPiece;
        _isEditing = false;
      }),
    );
    
    // Fetch additional data
    if (_piece.liveStatus) {
      _fetchAnchorDetails();
    }
    
    // Start impression refresh timer
    _fetchPieceImpressions();
    _impressionsRefreshTimer = Timer.periodic(
      Duration(seconds: _refreshIntervalSeconds), 
      (_) => _fetchPieceImpressions()
    );
  }

  @override
  void dispose() {
    _impressionsRefreshTimer?.cancel();
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _paymentDetailsController.dispose();
    _currencyController.dispose();
    super.dispose();
  }
// piece_preview_popup.dart (continued)
  Future<void> _fetchAnchorDetails() async {
    try {
      setState(() {
        _isLoadingAnchorDetails = true;
      });

      var pieceData = jsonDecode(widget.pieceData);
      String pieceId = pieceData['PieceID'];

      final anchorRepository = ref.read(anchorRepositoryProvider);
      final response = await anchorRepository.getAnchorByPieceId(pieceId);

      if (response.data != null && response.data!.expireTime != null) {
        setState(() {
          _anchorExpireTime = response.data!.expireTime;
        });
      }
    } catch (e) {
      print('Error fetching anchor details: $e');
    } finally {
      setState(() {
        _isLoadingAnchorDetails = false;
      });
    }
  }

  Future<void> _fetchPieceImpressions() async {
    try {
      // Parse the piece data to get the piece ID
      var pieceData = jsonDecode(widget.pieceData);
      String pieceId = pieceData['PieceID'];
      
      if (pieceId.isNotEmpty) {
        final pieceRepository = ref.read(pieceRepositoryProvider);
        final impressions = await pieceRepository.getPieceImpressions(pieceId);
        
        if (mounted) {
          setState(() {
            // This updates the local state to show in the UI
            _piece = _piece.copyWith(pieceImpressions: impressions);
          });
          print('[IMP] Updated impressions count: $impressions');
        }
      }
    } catch (e) {
      print('[IMP] Error fetching impressions: $e');
    }
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
        Navigator.of(context).pop();
      }
    } catch (e) {
      print('Error during closing: $e');
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  void _handleUnityMessage(String message) {
    print('Received message from Unity: $message');
    // Unity messages are now handled in PieceUnityViewer
  }

  void _setErrorMessage(String message) {
    setState(() {
      _errorMessage = message;
      _isLoading = false;
    });
    print('Error: $message');
  }

  void _handleOwnershipChanged(String value) {
    setState(() {
      _ownership = value;
    });
  }

  Future<void> _deletePiece() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      final pieceRepository = ref.read(pieceRepositoryProvider);
      final response = await pieceRepository.deletePiece(
          _piece.pieceTitle, _piece.pieceOwner);
      
      if (response.isSuccess && mounted) {
        // First safely dispose the Unity controller before navigation
        final sceneManager = ref.read(unitySceneManagerProvider);
        if (sceneManager.isUnityInitialized) {
          try {
            await sceneManager.safeDisposeController();
          } catch (e) {
            print('Error disposing Unity controller during piece deletion: $e');
          }
        }
        
        // Now navigate after controller is properly disposed
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const UserProfileScreen(
                successMessage: 'Piece deleted successfully',
              ),
            ),
          );
        }
        return;
      }
      
      ref.read(errorProvider.notifier).setError(response.message ?? 'Failed to delete piece');
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

  void _showPopup(BuildContext context) {
    final user = ref.read(userProvider);
    final username = user?.username;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Piece Live Placement'),
          content: Text('Proceed to place this piece live?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
            TextButton(
              onPressed: () async {
                final String pieceDataToPass = widget.pieceData;
                final String usernameToPass = username!;

                if (mounted) {
                  Navigator.of(context).pop(); // pop alert dialog
                  Navigator.of(context).pop(); // pop piece preview popup

                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => UnityARViewPlacement(
                        pieceData: pieceDataToPass, 
                        username: usernameToPass
                      )
                    )
                  );
                }
              },
              child: Text('Proceed'),
            ),
          ],
        );
      },
    );
  }

  void _liveStatusChange() {
    if (_piece.liveStatus) {
      // Turn offline
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Turn Piece Offline'),
            content: Text('Are you sure you want to turn this piece offline? Users will not be able to view it and its specific location will be lost.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('Cancel'),
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
                    final response = await pieceRepository.togglePieceLiveStatus(pieceId, false);
                    if (response.isSuccess) {
                      setState(() {
                        _piece = _piece.copyWith(liveStatus: false);
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
      // Turn online (place in AR)
      _showPopup(context);
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
        child: SizedBox(
          width: _isFullScreen
              ? MediaQuery.of(context).size.width * 0.95 // Wider in full-screen
              : MediaQuery.of(context).size.width * 0.8, // Normal width
          height: _isFullScreen
              ? MediaQuery.of(context).size.height * 0.8 // Taller in full-screen
              : MediaQuery.of(context).size.height * 0.8,
          child: Column(
            children: [
              AppBar(
                title: Text(_piece.pieceTitle),
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    _handleClosing();
                  }
                ),
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
                  if (!_isFullScreen && !widget.isReadOnly) // Only show these buttons when not in full-screen
                    IconButton(
                      icon: Icon(_isEditing ? Icons.save : Icons.edit),
                      onPressed: () {
                        setState(() {
                          if (_isEditing) {
                            _editManager.savePieceChanges().then((success) {
                              if (success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Piece updated successfully')),
                                );
                                widget.onPieceUpdated();
                              }
                            });
                          } else {
                            _isEditing = true;
                          }
                        });
                      },
                    ),
                  if (!_isFullScreen && _isEditing && !widget.isReadOnly) // Only show delete in normal mode and edit mode
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _editManager.showDeleteConfirmation(context, _deletePiece),
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

              // Unity View component
              PieceUnityViewer(
                pieceData: widget.pieceData,
                isFullScreen: _isFullScreen,
                onUnityMessage: _handleUnityMessage,
                onErrorMessage: _setErrorMessage,
                isLoading: _isLoading,
              ),
              
              // Details section below Unity view
   if (!_isFullScreen)
                Expanded(
                  child: PieceInfoSection(
                    piece: _piece,
                    isEditing: _isEditing,
                    nameController: _nameController,
                    descriptionController: _descriptionController,
                    priceController: _priceController,
                    currencyController: _currencyController, // Add this
                    isLoadingAnchorDetails: _isLoadingAnchorDetails,
                    anchorExpireTime: _anchorExpireTime,
                    ownership: _ownership,
                    onOwnershipChanged: _handleOwnershipChanged,
                    onForSaleChanged: (value) {
                      setState(() {
                        _piece = _piece.copyWith(pieceForSale: value);
                      });
                    },
                    context: context,
                  ),
                ),
              
              // Action buttons section (for editing and sales)
              if (!_isFullScreen && _isEditing && !widget.isReadOnly)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          _editManager.savePieceChanges().then((success) {
                            if (success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Piece updated successfully')),
                              );
                              widget.onPieceUpdated();
                            }
                          });
                        },
                        child: const Text('Save Changes'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          _liveStatusChange();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _piece.liveStatus
                              ? Colors.red
                              : Colors.green,
                        ),
                        child: _piece.liveStatus
                            ? const Text('Turn offline')
                            : const Text('Turn online'),
                      ),
                    ],
                  ),
                ),
              
              // Make offer button (for other users viewing this piece)
              if (!_isFullScreen && widget.isReadOnly && _piece.pieceForSale)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.local_offer),
                    label: const Text('Make Offer'),
                    onPressed: () => _offerManager.showMakeOfferDialog(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                ),
              
              // Location buttons (only for live pieces)
              if (!_isFullScreen && _piece.liveStatus)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0, left: 16.0, right: 16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.location_on),
                          label: const Text('Locate'),
                          onPressed: () => _locationManager.showPieceLocationMap(context),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.share_location),
                          label: const Text('Share Location'),
                          onPressed: () => _locationManager.shareLocation(context),
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
    );
  }
}