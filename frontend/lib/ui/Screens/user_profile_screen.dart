import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frames_app/models/anchor_model.dart';
import 'package:frames_app/models/piece_model.dart';
import 'package:frames_app/models/user_model.dart';
import 'package:frames_app/providers/user_provider.dart';
import 'package:frames_app/ui/Screens/user_menu.dart';
import 'package:frames_app/ui/Widgets/piece_preview_popup.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:frames_app/ui/Screens/subscribers_screen.dart';
import 'package:frames_app/ui/Screens/subscriptions_screen.dart';

class UserProfileScreen extends ConsumerStatefulWidget {
  final String? successMessage;

  const UserProfileScreen({
    super.key,
    this.successMessage,
  });

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> {
  bool _showGallery = true;
  final bool _isLoading = false;
  bool _manualRefreshInProgress = false;
  bool _showHidden = false; 


  Completer<GoogleMapController> _mapController = Completer();
  LatLng? _currentUserLocation;

  @override
  void initState() {
    super.initState();

    // Request location permission
    requestLocationPermission();

    // Show success message if it exists
    if (widget.successMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(widget.successMessage!)));
        }
      });
    }

     // Silent refresh when entering the screen without showing loading indicator
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _silentRefresh();
    });
  }
  

  Future<void> requestLocationPermission() async {
    final permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      setState(() {
        _currentUserLocation = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      print('Error getting current location: $e');
    }
  }

  @override
  void dispose() {
    _disposeMapController();
    super.dispose();
  }

  void _refreshProfileData({bool showLoading = true}) async {
    if (showLoading) {
      await ref
          .read(userNotifierProvider)
          .refreshUserData(showLoading: showLoading);
    } else {
      await ref.read(userNotifierProvider).refreshUserData(showLoading: false);
    }

    // Force a rebuild after the refresh
    if (mounted) {
      setState(() {});
    }
  }
/** 
   // CHANGES: Addded this function
  Future<void> _loadUserProfileData() async {
    // Moved user data loading to its own function
    try {
      final userModel = ref.read(userProfileProvider); // Use ref.read here
      if (userModel!.pieces.isEmpty) {
        //error
        ref.read(errorProvider.notifier).setError('[LOGS] User ${userModel.username} has no pieces');
        setState(() {
          _isLoading = false;
        });
        return; // Important: Exit if user data loading fails
      }
    } catch (e) {
      ref.read(errorProvider.notifier).setError('[LOGS] Error loading user data: $e');
      setState(() {
        _isLoading = false;
      });
      return; // Important: Exit if user data loading fails
    }
  }
  */

// Silent refresh without showing loading overlay
  Future<void> _silentRefresh() async {
    if (mounted) {
      await ref.read(userNotifierProvider).refreshUserData(showLoading: false);
      setState(() {});
    }
  }

  // Manual refresh with loading indicator (triggered by button)
  void _manualRefresh() async {
    setState(() {
      _manualRefreshInProgress = true;
    });

    await ref.read(userNotifierProvider).refreshUserData(showLoading: true);

    if (mounted) {
      setState(() {
        _manualRefreshInProgress = false;
      });
    }
  }

  @override
  @override
Widget build(BuildContext context) {
  final userModel = ref.watch(userProfileProvider);
  print('[LOGS] User profile data for : ${userModel!.username}. Has ${userModel.pieces.length} pieces');
  final bool isLoading = _isLoading;
  
  return PopScope(
    canPop: false,
    onPopInvoked: (didPop) {
      if (didPop) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MenuScreen()),
      );
    },
    child: Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const MenuScreen()),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // TODO: Implement edit functionality
            },
          ),
          IconButton(
            icon: _manualRefreshInProgress
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.refresh),
            onPressed: _manualRefreshInProgress ? null : _manualRefresh,
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildProfileInfoRow(userModel),
            const SizedBox(height: 16),
            _buildToggleRow(),
            Expanded(
              child: _showGallery
                  ? _buildGalleryView(userModel.pieces)
                  : _buildMapView(userModel.anchors, userModel.pieces),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildProfileInfoRow(UserModel userProfile) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () {
                  // TODO: Implement profile picture change
                },
                child: CircleAvatar(
                  radius: 40,
                  backgroundImage: userProfile.profilePhoto.isNotEmpty
                      ? NetworkImage(userProfile.profilePhoto)
                      : const NetworkImage('https://dummyimage.com/250/ffffff'),
                ),
              ),
              const SizedBox(height: 8),
              Text(userProfile.username,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(userProfile.bio, textAlign: TextAlign.center),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildCountColumn(
                          'Subscribers', userProfile.subscriberCount.toString(),
                          () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const SubscribersScreen(),
                          ),
                        );
                      }),
                      _buildCountColumn('Subscriptions',
                          userProfile.subscriptionCount.toString(), () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const SubscriptionsScreen(),
                          ),
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildCountColumn('Impressions',
                          userProfile.totalImpressions.toString(), null),
                      _buildCountColumn('Live Pieces',
                          userProfile.livePieces.toString(), null),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
Widget _buildGalleryView(List<Piece> pieces) {
  if (_isLoading) {
    return const Center(child: CircularProgressIndicator());
  }

  // DEBUG: Print toggle state and piece info
  print('[DEBUG] _showHidden toggle state: $_showHidden');
  print('[DEBUG] Total pieces: ${pieces.length}');
  
  // DEBUG: Check each piece's hidden status
  for (int i = 0; i < pieces.length; i++) {
    print('[DEBUG] Piece $i: ${pieces[i].pieceTitle} - isHidden: ${pieces[i].isHidden}');
  }

  // Filter pieces based on hidden toggle
  List<Piece> filteredPieces = pieces;
  
  if (!_showHidden) {
    // Hide hidden pieces when toggle is off
    filteredPieces = pieces.where((piece) => !piece.isHidden).toList();
    print('[DEBUG] After filtering (showHidden=false): ${filteredPieces.length} pieces');
  } else {
    print('[DEBUG] Showing all pieces (showHidden=true): ${pieces.length} pieces');
  }
  
  // DEBUG: Print filtered pieces
  for (int i = 0; i < filteredPieces.length; i++) {
    print('[DEBUG] Filtered piece $i: ${filteredPieces[i].pieceTitle} - isHidden: ${filteredPieces[i].isHidden}');
  }

  if (filteredPieces.isEmpty) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_library_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            _showHidden 
                ? 'No pieces found'
                : 'No visible pieces found',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          if (!_showHidden && pieces.any((piece) => piece.isHidden)) ...[
            const SizedBox(height: 8),
            Text(
              'Turn on "Show Hidden" to see hidden pieces',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ],
      ),
    );
  }

  return GridView.builder(
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 3,
      childAspectRatio: 1,
    ),
    itemCount: filteredPieces.length,
    itemBuilder: (context, index) {
      return _buildPieceItem(filteredPieces[index]);
    },
  );
}

  Widget _buildCountColumn(String label, String count, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(count, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildToggleRow() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Gallery'),
          Switch(
            value: !_showGallery,
            onChanged: (value) {
              setState(() {
                _showGallery = !value;
              });

              if (!_showGallery) {
                // When switching back to gallery, dispose of the map controller
                _disposeMapController();
              }
            },
          ),
          const Text('Map'),
          
          // NEW: Add Show Hidden toggle (only visible in gallery view)
          if (_showGallery) ...[
            const SizedBox(width: 20),
            const Text('Show Hidden'),
            Switch(
              value: _showHidden,
              onChanged: (value) {
                setState(() {
                  _showHidden = value;
                });
              },
            ),
          ],
        ],
      ),
    );
  }


  void _showPiecePreview(BuildContext context, Piece piece) {
    print("Opening piece preview for: ${piece.pieceTitle} (${piece.pieceid})");

    showDialog(
      context: context,
      builder: (BuildContext context) {
        print(
            'TESTING PiecePreviewPopup: Creating fresh piece data for ${piece.pieceTitle}, Frame_name = ${piece.frameName}, ownership = ${piece.ownership}');
        String freshPieceData = jsonEncode({
          'frameName': piece.frameName,
          'faceName': 'Face',
          'imageUrl': piece.pieceDisplay,
          'PieceID': piece.pieceid,
        });
        print('[TEST] Fresh piece data being sent to preview: $freshPieceData');
        print('[IMP] piece.pieceImpressions: ${piece.pieceImpressions}');

        return PiecePreviewPopup(
          piece: piece,
          pieceData: freshPieceData,
          onPieceUpdated: () {
            print("Piece updated callback triggered for: ${piece.pieceTitle}");
    // Do a full refresh to ensure data is updated
    _silentRefresh(); // This will refresh the user data
          },
        );
      },
    );
  }

    Widget _buildPieceItem(Piece piece) {
    print('[LOGS] Building piece item for: ${piece.pieceTitle} (${piece.pieceid}). The url is: ${piece.pieceDisplay.toString()}');
    return GestureDetector(
      onTap: () => _showPiecePreview(context, piece),
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image with loading indicator
            Image.network(
              piece.pieceDisplay ?? 'https://dummyimage.com/250/ffffff',
              fit: BoxFit.cover,
              loadingBuilder: (BuildContext context, Widget child,
                  ImageChunkEvent? loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.error, color: Colors.red),
                );
              },
            ),
            
            // Live status indicator
            if (piece.liveStatus)
              Positioned(
                top: 4,
                left: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'LIVE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            
            // NEW: Hidden indicator
            if (piece.isHidden)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'HIDDEN',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            
            // For sale indicator  
            if (piece.pieceForSale)
              Positioned(
                bottom: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'FOR SALE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  Widget _buildMapView(List<AnchorModel> anchors, List<Piece> pieces) {
    if (anchors.isEmpty && _currentUserLocation == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('No live pieces placed on map'),
            SizedBox(height: 8),
            Text('Try creating and placing a piece first!',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    // Create markers and circles for the user's own pieces
    Set<Marker> markers = {};
    Set<Circle> circles = {}; // NEW: Add circles for hidden pieces

    // Add piece markers
    markers.addAll(anchors.map((anchor) {
      Piece? matchingPiece;
      try {
        matchingPiece = pieces.firstWhere(
          (piece) => piece.pieceid == anchor.pieceId,
        );
      } catch (e) {
        print('No matching piece found for anchor: ${anchor.pieceId}');
      }

      final position = LatLng(
        anchor.location.coordinates[1], 
        anchor.location.coordinates[0]
      );

      // For user's own profile, always show exact markers
      // But add visual distinction for hidden pieces
      final marker = Marker(
        markerId: MarkerId(anchor.anchorId),
        position: position,
        infoWindow: InfoWindow(
          title: matchingPiece?.pieceTitle ?? anchor.frameName,
          snippet: matchingPiece?.isHidden == true 
              ? 'Hidden piece • Tap to view details'
              : 'Tap to view details',
        ),
        onTap: () {
          if (matchingPiece != null) {
            _showPiecePreview(context, matchingPiece);
          }
        },
        icon: matchingPiece?.isHidden == true
            ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange)
            : BitmapDescriptor.defaultMarker,
      );

      // NEW: Add radius circles for hidden pieces to show their coverage area
      if (matchingPiece?.isHidden == true && (matchingPiece?.showRadius ?? 0) > 0) {
        circles.add(
          Circle(
            circleId: CircleId('radius_${anchor.anchorId}'),
            center: position,
            radius: (matchingPiece?.showRadius ?? 0).toDouble(),
            fillColor: Colors.orange.withOpacity(0.1),
            strokeColor: Colors.orange.withOpacity(0.5),
            strokeWidth: 1,
          ),
        );
      }

      return marker;
    }));

    // Add user location marker if available
    if (_currentUserLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('user_location'),
          position: _currentUserLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: const InfoWindow(title: 'Your Location'),
        ),
      );
    }

    // Determine initial camera position
    LatLng initialPosition = _currentUserLocation ??
        (anchors.isNotEmpty
            ? LatLng(anchors.first.location.coordinates[1],
                anchors.first.location.coordinates[0])
            : const LatLng(0, 0)); // Default position if no anchors

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: initialPosition,
        zoom: 15,
      ),
      markers: markers,
      circles: circles, // NEW: Add circles to show hidden piece radius
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      mapToolbarEnabled: false,
      zoomControlsEnabled: true,
      onMapCreated: (GoogleMapController controller) {
        if (!_mapController.isCompleted) {
          _mapController.complete(controller);
          if (markers.isNotEmpty) {
            _fitBounds(markers);
          }
        }
      },
    );
  }

  // Add this helper function to fit all markers in view
  Future<void> _fitBounds(Set<Marker> markers) async {
    if (markers.isEmpty) return;

    double minLat = markers.first.position.latitude;
    double maxLat = markers.first.position.latitude;
    double minLng = markers.first.position.longitude;
    double maxLng = markers.first.position.longitude;

    for (final marker in markers) {
      if (marker.position.latitude < minLat) minLat = marker.position.latitude;
      if (marker.position.latitude > maxLat) maxLat = marker.position.latitude;
      if (marker.position.longitude < minLng)
        minLng = marker.position.longitude;
      if (marker.position.longitude > maxLng)
        maxLng = marker.position.longitude;
    }

    final GoogleMapController controller = await _mapController.future;
    controller.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        50, // padding
      ),
    );
  }

  void _disposeMapController() async {
    if (_mapController.isCompleted) {
      final controller = await _mapController.future;
      controller.dispose();
      _mapController = Completer<GoogleMapController>();
    }
  }
}