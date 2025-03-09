// piece_preview_popup.dart

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:flutter_unity_widget/flutter_unity_widget.dart';
import 'package:frames_app/Functions/piece_loading.dart';
import 'package:frames_app/Functions/toggle_live_status.dart';
import 'package:frames_app/Providers/user_profile_info.dart';
import 'package:frames_app/Screens/user_profile_screen.dart';
import 'package:frames_app/Widgets/AR_Piece_placement.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class PiecePreviewPopup extends ConsumerStatefulWidget {
  String pieceName;
  final String pieceData;
  bool liveStatus;
  final String pieceOwner;
  String? pieceDescription;
  double piecePrice;
  int pieceLikes;
  bool pieceForSale;
  final DateTime pieceCreationDate;
  final Function onPieceUpdated;

  PiecePreviewPopup({
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
  bool _isLoading = true;
  bool _isCorrectSceneLoaded = false;
  bool _isSceneReady = false;
  bool _isClosing = false;
  bool isTextureCompleted = false;

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  final List<Anchor> _anchors = [];
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
          title: Text('Delete Piece'),
          content: Text(
              'Are you sure you want to delete this piece? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _deletePiece();
                Navigator.of(context).pop(); // Close dialog
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deletePiece() async {
    try {
      final url =
          Uri.parse('https://x-fabric-419423.uc.r.appspot.com/delete_piece');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'piece_title': widget.pieceName,
          'piece_owner': widget.pieceOwner,
        }),
      );

      if (response.statusCode == 200) {
        // Success - close preview and return to profile
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => UserProfileScreen(
              username: widget.pieceOwner,
              successMessage: 'Piece deleted successfully',
            ),
          ),
        );
      } else {
        throw Exception('Failed to delete piece');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete piece: $e')),
      );
    }
  }

  void _showPieceLocationMap() async {
    var pieceData = jsonDecode(widget.pieceData);
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator()),
    );

    final anchor = await _loadAnchorByPieceId(pieceData['PieceID']);

    Navigator.pop(context);

    if (anchor != null) {
      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) => Container(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Piece Location',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: Icon(Icons.close),
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
                          markerId: MarkerId('piece_location'),
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
                        icon: Icon(Icons.directions),
                        label: Text('Get Directions'),
                        onPressed: () {
                          _openGoogleMapsNavigation(
                              anchor.location.coordinates[1],
                              anchor.location.coordinates[0]);
                        },
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12),
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
          SnackBar(content: Text('Could not load piece location')));
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
            SnackBar(content: Text('Could not launch navigation')));
      }
    }
  }

  Future<void> _shareLocation() async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(child: CircularProgressIndicator()),
      );

      // Get piece data
      var pieceData = jsonDecode(widget.pieceData);
      final anchor = await _loadAnchorByPieceId(pieceData['PieceID']);

      // Dismiss loading indicator
      Navigator.pop(context);

      if (anchor != null) {
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
              title: Text('Location Copied!'),
              content: Column(
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
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not get piece location')));
      }
    } catch (e) {
      print('Error sharing location: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error sharing location')));
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text('$label: ', style: TextStyle(fontWeight: FontWeight.bold)),
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
          Text('$label: ', style: TextStyle(fontWeight: FontWeight.bold)),
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
            title: Text('Turn Piece Offline'),
            content: Text(
                'Are you sure you want to turn this piece offline? Users will not be able to view it and its specific location will be lost.'),
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
                    widget.liveStatus = false;
                  });
                  var decodedData = jsonDecode(widget.pieceData);
                  String pieceId = decodedData['PieceID'];
                  await togglePieceLiveStatus(pieceId, false);
                  print('Piece live status updated to False');
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserProfileScreen(
                        username: widget.pieceOwner,
                        successMessage: 'Piece turned offline successfully',
                      ),
                    ),
                  );
                },
                child: Text('Turn Offline'),
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
    final username = ref.watch(userProfileInfoProvider)?.username;

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

                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => UnityARViewPlacement(
                          pieceData: pieceDataToPass,
                          username: usernameToPass)));
                }
              },
              child: Text('Proceed'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _savePieceChanges() async {
    setState(() {
      _isEditing = false;
    });

    final url =
        Uri.parse('https://x-fabric-419423.uc.r.appspot.com/update_piece');

    try {
      final response = await http.put(
        url,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          "piece_owner": widget.pieceOwner,
          "old_piece_title": widget.pieceName,
          "new_piece_title": _nameController.text,
          "updated_piece_description": _descriptionController.text,
          "piece_for_sale": widget.pieceForSale,
          "piece_price": double.tryParse(_priceController.text) ?? 0.0,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('Piece updated successfully: ${responseData['message']}');

        setState(() {
          widget.pieceName = _nameController.text;
          widget.pieceDescription = _descriptionController.text;
          if (widget.pieceForSale) {
            widget.piecePrice =
                double.tryParse(_priceController.text) ?? widget.piecePrice;
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Piece updated successfully')),
        );

        widget.onPieceUpdated();
        Navigator.of(context).pop();
      } else {
        print('Failed to update piece. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to update piece. Please try again.')),
        );
      }
    } catch (e) {
      print('Error updating piece: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred. Please try again.')),
      );
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

  Future<Anchor?> _loadAnchorByPieceId(String pieceId) async {
    print("_loadAnchorByPieceId called with pieceId: $pieceId");
    try {
      final url = Uri.parse(
          'https://x-fabric-419423.uc.r.appspot.com/get_anchor_by_piece_id');
      final requestBody = jsonEncode({'pieceId': pieceId});
      print("Sending request with body: $requestBody");

      final response = await http.post(
        url,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: requestBody,
      );

      print("Response status code: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("Raw anchor data: $data");

        final anchor = Anchor.fromJson(data);
        print('Anchor loaded successfully for piece: $pieceId');
        return anchor;
      } else {
        print(
            'Error loading anchor. Status: ${response.statusCode}, Body: ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      print('Error loading anchor: $e');
      print('Stack trace: $stackTrace');
      return null;
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
            ? EdgeInsets.all(8) // Minimal padding in full-screen
            : EdgeInsets.symmetric(
                horizontal: 40, vertical: 24), // Default padding
        child: Container(
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
                    icon: Icon(Icons.close),
                    onPressed: () {
                      _handleClosing();
                    }),
                actions: [
                  // Add this full-screen toggle button
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
                          }
                          _isEditing = !_isEditing;
                        });
                      },
                    ),
                  if (!_isFullScreen &&
                      _isEditing) // Only show delete in normal mode and edit mode
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: _showDeleteConfirmation,
                    ),
                ],
              ),
              if (_errorMessage.isNotEmpty && !_isFullScreen)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    _errorMessage,
                    style: TextStyle(color: Colors.red),
                  ),
                ),

              // Unity Widget container
              Container(
                height: _isFullScreen
                    ? MediaQuery.of(context).size.height *
                        0.7 // Larger Unity view in full-screen
                    : MediaQuery.of(context).size.height * 0.3,

                width: _isFullScreen
                    ? MediaQuery.of(context).size.width *
                        0.95 // Added width constraint
                    : double.infinity, // Take available width in normal mode

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
                        child: Text(
                          "Unity Widget Placeholder",
                          style: TextStyle(fontSize: 16),
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
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildEditableInfoRow('Piece Name', _nameController),
                        _buildInfoRow('Piece Owner', widget.pieceOwner),
                        _buildEditableInfoRow(
                            'Description', _descriptionController),
                        _buildInfoRow(
                            'Creation Date',
                            DateFormat('yyyy-MM-dd')
                                .format(widget.pieceCreationDate)),
                        _buildInfoRow('Likes', widget.pieceLikes.toString()),
                        _buildInfoRow('Live Status',
                            widget.liveStatus ? 'Live' : 'Not Live'),
                        Row(
                          children: [
                            Text('For Sale: ',
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
                              SizedBox(width: 8),
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
                                    ? Text('Turn offline')
                                    : Text('Turn online'),
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
                                    icon: Icon(Icons.location_on),
                                    label: Text('Locate'),
                                    onPressed: _showPieceLocationMap,
                                    style: ElevatedButton.styleFrom(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 8),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                    width: 8), // Add spacing between buttons
                                Expanded(
                                  child: ElevatedButton.icon(
                                    icon: Icon(Icons.share_location),
                                    label: Text('Share Location'),
                                    onPressed: _shareLocation,
                                    style: ElevatedButton.styleFrom(
                                      padding: EdgeInsets.symmetric(
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
