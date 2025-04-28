// piece_preview_popup.dart

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:flutter_unity_widget/flutter_unity_widget.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Add import for offer_provider
import 'package:frames_app/Providers/offer_provider.dart';
import 'package:frames_app/core/repositories/anchor_repository.dart';
import 'package:frames_app/core/repositories/piece_repository.dart';
import 'package:frames_app/core/services/map.dart';
import 'package:frames_app/models/anchor_model.dart';
import 'package:frames_app/providers/error_provider.dart';
import 'package:frames_app/providers/user_provider.dart';
import 'package:frames_app/ui/Screens/user_profile_screen.dart';
import 'package:frames_app/ui/Widgets/AR_Piece_placement.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

// Import for quill docs
// import 'package:flutter_quill/flutter_quill_extensions.dart';

//NEW IMPLEMENTATION

class PiecePreviewPopup extends ConsumerStatefulWidget {
  String pieceName;
  final String pieceData;
  bool liveStatus;
  final String pieceOwner;
  String? pieceDescription;
  double piecePrice;
  int pieceLikes;
  int impressions;
  bool pieceForSale;
  final DateTime pieceCreationDate;
  final Function onPieceUpdated;
  final bool isReadOnly; // Add this property to control edit permissions
  String? paymentDetails; // Added field for payment details

  PiecePreviewPopup({
    super.key,
    required this.pieceName,
    required this.pieceData,
    required this.liveStatus,
    required this.pieceOwner,
    required this.pieceDescription,
    required this.piecePrice,
    required this.pieceLikes,
    this.impressions = 0,
    required this.pieceForSale,
    required this.pieceCreationDate,
    required this.onPieceUpdated,
    this.isReadOnly = false, // Default to false for backward compatibility
    this.paymentDetails,
  });

  @override
  _PiecePreviewPopupState createState() => _PiecePreviewPopupState();
}

class _PiecePreviewPopupState extends ConsumerState<PiecePreviewPopup> {
  // UnityWidgetController? _unityWidgetController;
  final bool _isUnityLoaded = false;
  bool _isUnityInitializing = false;
  final bool _isSceneLoading = false;
  String _errorMessage = '';
  bool _isEditing = false;
  bool _isLoading = true;
  bool _isCorrectSceneLoaded = false;
  bool _isSceneReady = false;
  bool _isClosing = false;
  bool isTextureCompleted = false;
  DateTime? _anchorExpireTime;
  bool _isLoadingAnchorDetails = false;

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _paymentDetailsController;

  final List<AnchorModel> _anchors = [];
  bool _isFullScreen = false;
  Timer? _impressionsRefreshTimer;
  final int _refreshIntervalSeconds = 30; // Refresh every 30 seconds

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.pieceName);
    _descriptionController =
        TextEditingController(text: widget.pieceDescription);
    _priceController =
        TextEditingController(text: widget.piecePrice.toString());
    _paymentDetailsController =
        TextEditingController(text: widget.paymentDetails ?? '');

    // Initialize _isEditing to false and make sure it stays false if isReadOnly is true
    _isEditing = false;

    if (widget.liveStatus) {
      _fetchAnchorDetails();
    }
    _fetchPieceImpressions();
    _impressionsRefreshTimer = Timer.periodic(
        Duration(seconds: _refreshIntervalSeconds),
        (_) => _fetchPieceImpressions());
  }

  @override
  void dispose() {
    _impressionsRefreshTimer?.cancel();

    if (!_isClosing) {
      // _unityWidgetController?.dispose();
      // _unityWidgetController = null;
    }
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _paymentDetailsController.dispose();
    super.dispose();
  }

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
      if (kDebugMode) {
        print('Error fetching anchor details: $e');
      }
    } finally {
      setState(() {
        _isLoadingAnchorDetails = false;
      });
    }
  }

  Widget _buildExpiryTimeInfo() {
    if (!widget.liveStatus) {
      return const SizedBox.shrink(); // Don't show for non-live pieces
    }

    if (_isLoadingAnchorDetails) {
      return const Padding(
        padding: EdgeInsets.only(top: 8.0),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2.0)),
      );
    }

    if (_anchorExpireTime == null) {
      return const Padding(
        padding: EdgeInsets.only(top: 8.0),
        child: Text('Expiry time not available',
            style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
      );
    }

    // Calculate days remaining
    final now = DateTime.now();
    final difference = _anchorExpireTime!.difference(now);
    final daysRemaining = difference.inDays;

    // Choose color based on days remaining
    Color textColor = Colors.green;
    if (daysRemaining < 30) {
      textColor = Colors.orange;
    }
    if (daysRemaining < 7) {
      textColor = Colors.red;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        children: [
          const Text('Anchor Expires: ',
              style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('yyyy-MM-dd').format(_anchorExpireTime!),
                ),
                Text(
                  '$daysRemaining days remaining',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Future<void> _initializeUnityScene() async {
  //   if (_isSceneLoading) return;

  //   setState(() {
  //     _isSceneLoading = true;
  //     _isUnityInitializing = true;
  //     _isUnityLoaded = false;
  //     _errorMessage = '';
  //   });

  //   try {
  //     // Reset scene first
  //     _unityWidgetController?.postMessage(
  //         'GameManager', 'ResetUnityScene', 'reset');
  //     print('[LOGS] [_initializeUnityScene] Resetting Unity scene');

  //     // Wait for reset
  //     await Future.delayed(const Duration(milliseconds: 500));

  //     // Load new scene
  //     _unityWidgetController?.postMessage(
  //         'SceneLoader', 'LoadSceneByName', 'frames_test');

  //     // Wait for scene load
  //     await Future.delayed(const Duration(seconds: 1));

  //     setState(() {
  //       _isUnityLoaded = true;
  //     });

  //     // Now send piece data
  //     sendPieceDataToUnity();
  //   } catch (e) {
  //     setErrorMessage('Error initializing Unity scene: $e');
  //   } finally {
  //     if (mounted) {
  //       setState(() {
  //         _isSceneLoading = false;
  //         _isUnityInitializing = false;
  //       });
  //     }
  //   }
  // }

  // void onUnityCreated(UnityWidgetController controller) {
  //   print('Unity Widget created - controller: $controller');
  //   _unityWidgetController = controller;
  //   setState(() {
  //     _isClosing = false;
  //   });
  //   _initializeUnityScene();
  // }

  // void _onUnityMessage(message) {
  //   print('Received message from

  //   switch (message.toString()) {
  //     case 'TEXTURE_LOADING_STARTED':
  //       print('${DateTime.now()}: Processing TEXTURE_LOADING_STARTED');

  //       break;
  //     case 'TEXTURE_LOADING_COMPLETED':
  //       print('${DateTime.now()}: Processing TEXTURE_LOADING_COMPLETED');
  //       setState(() {
  //         isTextureCompleted = true;
  //       });

  //       break;
  //     case 'TEXTURE_LOADING_FAILED':
  //       print('${DateTime.now()}: Processing TEXTURE_LOADING_FAILED');

  //       break;
  //   }
  // }

  void _setSceneReady() {
    setState(() {
      _isLoading = false;
      _isCorrectSceneLoaded = true;
      _isSceneReady = true;
    });
    print('[LOGS] Scene is ready');
  }

  // void sendPieceDataToUnity() {
  //   if (_unityWidgetController == null) {
  //     setErrorMessage('Unity controller is not initialized');
  //     return;
  //   }
  //   if (!_isSceneReady) {
  //     print('Scene not ready, delaying sendPieceDataToUnity');
  //     return;
  //   }

  //   try {
  //     print(
  //         '[LOGS] Sending piece data to Unity for piece: ${widget.pieceName}');
  //     print('Data being sent: ${widget.pieceData}');

  //     _unityWidgetController!.postMessage(
  //       'GameManager',
  //       'ReceiveDataFromFlutter',
  //       widget.pieceData,
  //     );
  //     print(' [LOGS] Piece data sent to Unity successfully');
  //   } catch (e) {
  //     setErrorMessage('Error sending data to Unity: $e');
  //   }
  // }

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
    Navigator.pop(context);

    if (anchorResponse.data != null) {
      final anchor = anchorResponse.data!;

      if (!mounted) return;

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
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not load piece location')));
    }
  }

  void _openGoogleMapsNavigation(double lat, double lng) async {
    final url = Uri.parse('google.navigation:q=$lat,$lng&mode=w');
    if (!await launchUrl(url)) {
      // Fallback URL for web or if google.navigation doesn't work
      final webUrl = Uri.parse(
          'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=walking');
      if (!await launchUrl(webUrl)) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not launch navigation')));
      }
    }
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

    try {
      // _unityWidgetController?.postMessage(
      //     'GameManager', 'ResetUnityScene', 'reset');

      // await Future.delayed(const Duration(milliseconds: 500));

      // if (_unityWidgetController != null) {
      //   _unityWidgetController?.dispose();
      //   _unityWidgetController = null;
      // }

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

      // Convert the Quill document to JSON if for sale
      String? paymentDetails;
      if (widget.pieceForSale) {
        paymentDetails = _paymentDetailsController.text;
      }

      final response = await pieceRepository.updatePieceInfo(
        pieceOwner: widget.pieceOwner,
        oldPieceTitle: widget.pieceName,
        newPieceTitle: _nameController.text,
        pieceDescription: _descriptionController.text,
        pieceForSale: widget.pieceForSale,
        piecePrice: double.tryParse(_priceController.text) ?? 0.0,
        paymentDetails: paymentDetails,
      );

      if (response.isSuccess) {
        setState(() {
          widget.pieceName = _nameController.text;
          widget.pieceDescription = _descriptionController.text;
          if (widget.pieceForSale) {
            widget.piecePrice =
                double.tryParse(_priceController.text) ?? widget.piecePrice;
            widget.paymentDetails = _paymentDetailsController.text;
          }
          _isEditing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Piece updated successfully')),
        );

        // Explicitly refresh user data first - no showLoading to avoid UI flicker
        await ref
            .read(userNotifierProvider)
            .refreshUserData(showLoading: false);

        // Then make sure to call the callback
        widget.onPieceUpdated();
      } else {
        throw Exception(response.message ?? 'Failed to update piece');
      }
    } catch (e) {
      ref.read(errorProvider.notifier).setError('Failed to update piece: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
            widget.impressions = impressions;
          });
          print('[IMP] Updated impressions count: $impressions');
        }
      }
    } catch (e) {
      print('[IMP] Error fetching impressions: $e');
      // Don't update state on error
    }
  }

  Future<void> deletePiece() async {
    // TODO: Implement delete functionality
    print('Delete piece functionality to be implemented');
    // Suggested implementation steps:
    // 1. Make API call to delete piece
    // 2. Handle success/failure
    // 3. Update UI/navigate back
    // 4. Show success/error message
  }

  void _showMakeOfferDialog() {
    var pieceData = jsonDecode(widget.pieceData);
    String pieceId = pieceData['PieceID'];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Make an Offer'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Would you like to make an offer for ${widget.pieceName}?'),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('Price: ',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('\$${widget.piecePrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.green,
                      )),
                ],
              ),
              const SizedBox(height: 16),

              // Display payment details as read-only rich text if available
              if (widget.paymentDetails != null &&
                  widget.paymentDetails!.isNotEmpty) ...[
                const Text('Payment Details:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: TextField(
                    controller: _paymentDetailsController,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.all(8),
                      hintText: 'Enter payment details here...',
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 16),
              const Text(
                'By clicking "Make Offer", you agree to pay the listed price',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Show loading indicator
                Navigator.of(context).pop();
                Navigator.of(context).pop();

                final offerNotifier = ref.read(madeOffersProvider.notifier);
                offerNotifier.createOffer(
                  pieceId: pieceId,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Make Offer'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    print('[LOGS] isLoading is" $_isLoading');
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
                  if (!_isFullScreen &&
                      !widget
                          .isReadOnly) // Only show these buttons when not in full-screen
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
                      _isEditing &&
                      !widget
                          .isReadOnly) // Only show delete in normal mode and edit mode
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: _showDeleteConfirmation,
                    ),
                ],
              ),
              if (!_isFullScreen)
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildEditableInfoRow('Piece Name', _nameController),
                        _buildInfoRow('Piece Owner', widget.pieceOwner),
                        _buildEditableInfoRow(
                            'Description', _descriptionController),
                        if (widget.pieceForSale) ...[
                          _buildEditableInfoRow('Price', _priceController),

                          // Payment details section with rich text editor
                          if (_isEditing) ...[
                            const SizedBox(height: 10),
                            const Text('Payment Details:',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Container(
                              width: double.infinity,
                              height: 200,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: TextField(
                                controller: _paymentDetailsController,
                                maxLines: null,
                                expands: true,
                                textAlignVertical: TextAlignVertical.top,
                                decoration: const InputDecoration(
                                  contentPadding: EdgeInsets.all(8),
                                  hintText: 'Enter payment details here...',
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                          ] else if (widget.paymentDetails != null &&
                              widget.paymentDetails!.isNotEmpty) ...[
                            Container(
                              width: double.infinity,
                              height: 120,
                              padding: const EdgeInsets.all(8.0),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(4.0),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: SingleChildScrollView(
                                child: Text(
                                  widget.paymentDetails ?? '',
                                ),
                              ),
                            ),
                          ],
                        ],
                        _buildInfoRow('Likes', widget.pieceLikes.toString()),
                        _buildInfoRow(
                            'Impressions', widget.impressions.toString()),
                        _buildInfoRow('Live Status',
                            widget.liveStatus ? 'Live' : 'Not Live'),
                        _buildExpiryTimeInfo(),
                        Row(
                          children: [
                            const Text('For Sale: ',
                                style: TextStyle(fontWeight: FontWeight.bold)),
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
                          _buildEditableInfoRow('Price', _priceController),
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
                        if (widget.isReadOnly && widget.pieceForSale) ...[
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.local_offer),
                            label: const Text('Make Offer'),
                            onPressed: _showMakeOfferDialog,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 48),
                            ),
                          ),
                        ],
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
                                    icon: const Icon(Icons.share_location),
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
