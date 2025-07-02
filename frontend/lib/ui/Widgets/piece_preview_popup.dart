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
import 'package:frames_app/ui/Widgets/piece_flag_manager.dart';
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
  late PieceFlagManager _flagManager;

  // Refresh timer
  Timer? _impressionsRefreshTimer;
  final int _refreshIntervalSeconds = 30;

  // NEW: Added this helper method to check ownership
  bool _isCurrentUserOwner() {
    final currentUser = ref.watch(userProvider)?.username;
    return currentUser != null && currentUser == _piece.pieceOwner;
  }

  bool _shouldShowUnityView() {
    // Always show Unity view for piece owners
    if (_isCurrentUserOwner()) {
      return true;
    }

    // For non-owners, only show Unity view if piece is not hidden
    return !_piece.isHidden;
  }

  @override
  void initState() {
    super.initState();

    // Initialize the piece
    _piece = widget.piece;

    // Initialize controllers
    _nameController = TextEditingController(text: _piece.pieceTitle);
    _descriptionController =
        TextEditingController(text: _piece.pieceDescription);
    _priceController =
        TextEditingController(text: _piece.piecePrice.toString());
    _paymentDetailsController =
        TextEditingController(text: _piece.paymentDetails ?? '');
    _currencyController = TextEditingController(text: _piece.currency ?? 'USD');

    // Initialize ownership
    _ownership = _piece.ownership ?? '00';

    // Initialize managers
    _locationManager = PieceLocationManager(
      ref: ref,
      pieceId: jsonDecode(widget.pieceData)['PieceID'],
      pieceTitle: _piece.pieceTitle,
      piece: _piece,
    );

    _offerManager = PieceOfferManager(
      ref: ref,
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

    _flagManager = PieceFlagManager(
      ref: ref,
      piece: _piece,
    );

    // Fetch additional data
    if (_piece.liveStatus) {
      _fetchAnchorDetails(widget.pieceData);
    }

    // Start impression refresh timer
    _fetchPieceImpressions(widget.pieceData);
    _impressionsRefreshTimer = Timer.periodic(
        Duration(seconds: _refreshIntervalSeconds),
        (_) => _fetchPieceImpressions(widget.pieceData));
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

  Future<void> _fetchAnchorDetails(pieceData) async {
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

  Future<void> _fetchPieceImpressions(pieceData) async {
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

  // Replace your _handleClosing method in piece_preview_popup.dart with this:

  Future<void> _handleClosing() async {
    if (_isClosing) return; // Prevent multiple closing attempts

    setState(() {
      _isClosing = true;
    });

    print('[piece preview] Starting safe closure');

    try {
      // Cancel any ongoing timers first
      _impressionsRefreshTimer?.cancel();

      // Use the SceneManager to safely dispose the controller
      final sceneManager = ref.read(unitySceneManagerProvider);
      if (sceneManager.isUnityInitialized) {
        print('[piece preview] Safely disposing Unity controller');
        await sceneManager.safeDisposeController();
      } else {
        print('[piece preview] Unity not initialized, skipping disposal');
      }

      // Short delay to ensure everything is cleaned up
      await Future.delayed(const Duration(milliseconds: 100));

      if (mounted) {
        Navigator.of(context).pop();
        print('[piece preview] Successfully closed piece preview');
      }
    } catch (e) {
      print('[piece preview] Error during closing: $e');
      // Even if there's an error, try to close the dialog
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

  void _showPopup(BuildContext context) {
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

  void _liveStatusChange() {
    if (_piece.liveStatus) {
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
                  Navigator.of(context).pop(); // Close the confirmation dialog
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
                        _piece = _piece.copyWith(liveStatus: false);
                      });

                      // Close the confirmation dialog
                      Navigator.of(context).pop();

                      // Close the piece preview popup
                      Navigator.of(context).pop();

                      // Trigger refresh of the parent screen
                      widget.onPieceUpdated();

                      // Show success message
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Piece turned offline successfully'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                      return;
                    }
                    ref.read(errorProvider.notifier).setError(response.message);
                  } catch (e) {
                    ref
                        .read(errorProvider.notifier)
                        .setError('Failed to turn piece offline: $e');
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
            ? const EdgeInsets.all(8)
            : const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        // Use a scrollable dialog to ensure it doesn't overflow
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Use LayoutBuilder to get the max available height
            final maxHeight = constraints.maxHeight;

            return SingleChildScrollView(
              // Make the entire dialog scrollable if needed
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: _isFullScreen
                      ? MediaQuery.of(context).size.height * 0.8
                      : maxHeight.clamp(
                          0.0, MediaQuery.of(context).size.height * 0.8),
                  maxWidth: _isFullScreen
                      ? MediaQuery.of(context).size.width * 0.95
                      : MediaQuery.of(context).size.width * 0.8,
                ),
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min, // This is important to prevent overflow
                  children: [
                    // AppBar
                    AppBar(
                      title: Text(_piece.pieceTitle),
                      leading: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: _handleClosing,
                      ),
                      actions: [
                        // Add flag button for read-only mode (non-owners)
                        if (!_isFullScreen &&
                            widget.isReadOnly &&
                            !_isCurrentUserOwner())
                          IconButton(
                            icon: Icon(Icons.flag_outlined,
                                color: Colors.red[400]),
                            tooltip: 'Flag this piece',
                            onPressed: () =>
                                _flagManager.showFlagDialog(context),
                          ),
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
                        if (!_isFullScreen && !widget.isReadOnly)
                          IconButton(
                            icon: Icon(_isEditing ? Icons.save : Icons.edit),
                            onPressed: () {
                              setState(() {
                                if (_isEditing) {
                                  _editManager
                                      .savePieceChanges()
                                      .then((success) {
                                    if (success) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Piece updated successfully')),
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
                        if (!_isFullScreen && _isEditing && !widget.isReadOnly)
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _editManager
                                .showDeleteConfirmation(context, _deletePiece),
                          ),
                      ],
                    ),

                    // Error message
                    if (_errorMessage.isNotEmpty && !_isFullScreen)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          _errorMessage,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),

                    // Unity View component with smaller, adaptive height
                    SizedBox(
                      height: _isFullScreen
                          ? MediaQuery.of(context).size.height * 0.7
                          : (maxHeight * 0.3).clamp(150.0, 300.0),
                      child: _shouldShowUnityView()
                          ? PieceUnityViewer(
                              pieceData: widget.pieceData,
                              isFullScreen: _isFullScreen,
                              onUnityMessage: _handleUnityMessage,
                              onErrorMessage: _setErrorMessage,
                              isLoading: _isLoading,
                            )
                          : _buildHiddenPieceView(), // NEW: Show hidden message instead
                    ),

                    // Scrollable details section
                    if (!_isFullScreen)
                      Flexible(
                        // Use Flexible instead of Expanded to avoid overflow
                        fit: FlexFit.loose, // Allow taking less space if needed
                        child: Padding(
                          padding: EdgeInsets.only(
                            bottom: MediaQuery.of(context).viewInsets.bottom,
                          ),
                          child: SingleChildScrollView(
                            child: PieceInfoSection(
                              piece: _piece,
                              isEditing: _isEditing,
                              nameController: _nameController,
                              descriptionController: _descriptionController,
                              priceController: _priceController,
                              currencyController: _currencyController,
                              paymentDetailsController:
                                  _paymentDetailsController,
                              isLoadingAnchorDetails: _isLoadingAnchorDetails,
                              anchorExpireTime: _anchorExpireTime,
                              ownership: _ownership,
                              onOwnershipChanged: _handleOwnershipChanged,
                              onForSaleChanged: (value) {
                                setState(() {
                                  _piece = _piece.copyWith(pieceForSale: value);
                                  _editManager.updateForSaleState(value);
                                });
                              },
                              onHiddenChanged: (value) {
                                setState(() {
                                  _piece = _piece.copyWith(isHidden: value);
                                  _editManager.updateHiddenState(value);
                                });
                              },
                              onShowRadiusChanged: (value) {
                                setState(() {
                                  _piece = _piece.copyWith(showRadius: value);
                                  _editManager.updateShowRadius(value);
                                });
                              },
                              context: context,
                            ),
                          ),
                        ),
                      ),

                    // Action buttons - wrap in container with minimum height
                    if (!_isFullScreen && _isEditing && !widget.isReadOnly)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  _editManager
                                      .savePieceChanges()
                                      .then((success) {
                                    if (success) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Piece updated successfully')),
                                      );
                                      widget.onPieceUpdated();
                                    }
                                  });
                                },
                                child: const Text('Save Changes'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
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
                            ),
                          ],
                        ),
                      ),

                    // Make offer button with adaptive padding
                    if (!_isFullScreen &&
                        widget.isReadOnly &&
                        _piece.pieceForSale)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.local_offer),
                                label: const Text('Make Offer'),
                                onPressed: () =>
                                    _offerManager.showMakeOfferDialog(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(double.infinity, 40),
                                ),
                              ),
                            ),
                            // Add flag button for non-owners
                            if (!_isCurrentUserOwner()) ...[
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.flag_outlined, size: 16),
                                label: const Text('Flag'),
                                onPressed: () =>
                                    _flagManager.showFlagDialog(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red[50],
                                  foregroundColor: Colors.red[700],
                                  minimumSize: const Size(80, 40),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                    // Add flag button when piece is not for sale but user is not owner
                    if (!_isFullScreen &&
                        widget.isReadOnly &&
                        !_piece.pieceForSale &&
                        !_isCurrentUserOwner())
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.flag_outlined, size: 16),
                          label: const Text('Flag Piece'),
                          onPressed: () => _flagManager.showFlagDialog(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[50],
                            foregroundColor: Colors.red[700],
                            minimumSize: const Size(double.infinity, 40),
                          ),
                        ),
                      ),

                    // Location buttons with adaptive padding
                    if (!_isFullScreen && _piece.liveStatus)
                      Container(
                        padding: const EdgeInsets.only(
                            bottom: 8.0, left: 16.0, right: 16.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.location_on,
                                    size: 16), // Smaller icon
                                label: const Text('Locate',
                                    style: TextStyle(
                                        fontSize: 12)), // Smaller text
                                onPressed: () => _locationManager
                                    .showPieceLocationMap(context),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4), // Smaller padding
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.share_location,
                                    size: 16), // Smaller icon
                                label: const Text('Share Location',
                                    style: TextStyle(
                                        fontSize: 12)), // Smaller text
                                onPressed: () =>
                                    _locationManager.shareLocation(context),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4), // Smaller padding
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
          },
        ),
      ),
    );
  }

  Widget _buildHiddenPieceView() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.visibility_off,
            size: 64,
            color: Colors.orange[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Hidden Piece',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.orange[700],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'This piece is hidden by the creator.\nYou can only view it in AR mode.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange[100],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'Hidden',
              style: TextStyle(
                color: Colors.orange[700],
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
