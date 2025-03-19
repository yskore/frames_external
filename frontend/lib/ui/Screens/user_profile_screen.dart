import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frames_app/models/anchor_model.dart';
import 'package:frames_app/models/piece_model.dart';
import 'package:frames_app/models/user_profile_model.dart';
import 'package:frames_app/providers/user_provider.dart';
import 'package:frames_app/ui/Screens/user_menu.dart';
import 'package:frames_app/ui/Widgets/piece_preview_popup.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
          _refreshProfileData();
        }
      });
    }
  }

  Future<void> requestLocationPermission() async {
    final permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      _getCurrentLocation();
    }
  }

  @override
  void dispose() {
    _disposeMapController();
    super.dispose();
  }

  void _refreshProfileData({bool showLoading = true}) async {
    await ref
        .read(userNotifierProvider)
        .refreshUserData(showLoading: showLoading);
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
  Widget build(BuildContext context) {
    // Get user profile from provider
    final userProfile = ref.watch(userProfileProvider);
    final bool isLoading = _isLoading || userProfile == null;

    print(userProfile?.pieces.map((p) => p.pieceTitle).toList());

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Stack(
                children: [
                  Column(
                    children: [
                      const SizedBox(height: 56),
                      _buildProfileInfoRow(userProfile),
                      const SizedBox(height: 16),
                      _buildToggleRow(),
                      Expanded(
                        child: _showGallery
                            ? _buildGalleryView(userProfile.pieces)
                            : _buildMapView(
                                userProfile.anchors, userProfile.pieces),
                      ),
                    ],
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                              builder: (context) => const MenuScreen()),
                        );
                      },
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _refreshProfileData,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildProfileInfoRow(UserProfileModel userProfile) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
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
                      backgroundImage: userProfile.Profile_photo.isNotEmpty
                          ? NetworkImage(userProfile.Profile_photo)
                          : const NetworkImage(
                              'https://via.placeholder.com/80'),
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildCountColumn(
                        'Followers', userProfile.followerCount.toString()),
                    _buildCountColumn(
                        'Following', userProfile.followingCount.toString()),
                    _buildCountColumn(
                        'Live Pieces', userProfile.live_pieces.toString()),
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // TODO: Implement edit functionality
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGalleryView(List<Piece> pieces) {
    if (pieces.isEmpty) {
      return const Center(child: Text('No pieces available'));
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1,
      ),
      itemCount: pieces.length,
      itemBuilder: (context, index) {
        return _buildPieceItem(pieces[index]);
      },
    );
  }

  Widget _buildCountColumn(String label, String count) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(count, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
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
        ],
      ),
    );
  }

  void _showPiecePreview(BuildContext context, Piece piece) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        print(
            '[TEST] PiecePreviewPopup: Creating fresh piece data for ${piece.pieceTitle}, Frame_name = ${piece.frameName}');
        String freshPieceData = jsonEncode({
          'frameName': piece.frameName,
          'faceName': 'Face',
          'imageUrl': piece.pieceDisplay,
          'PieceID': piece.pieceid,
        });
        print('[TEST] Fresh piece data being sent to preview: $freshPieceData');

        return PiecePreviewPopup(
          pieceName: piece.pieceTitle,
          pieceData: freshPieceData,
          liveStatus: piece.liveStatus,
          pieceDescription: piece.pieceDescription,
          pieceLikes: piece.pieceLikes,
          pieceForSale: piece.pieceForSale,
          pieceCreationDate: piece.pieceCreationDate,
          piecePrice: piece.piecePrice,
          pieceOwner: piece.pieceOwner,
          onPieceUpdated: () {
            _refreshProfileData(showLoading: false);
          },
        );
      },
    );
  }

  Widget _buildPieceItem(Piece piece) {
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
              piece.pieceDisplay ?? 'https://via.placeholder.com/150',
              fit: BoxFit.cover,
              loadingBuilder: (BuildContext context, Widget child,
                  ImageChunkEvent? loadingProgress) {
                if (loadingProgress == null) {
                  return child;
                }
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                    strokeWidth: 2.0,
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Icon(Icons.error_outline, color: Colors.red),
                );
              },
            ),
            // Status overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                color: Colors.black54,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      piece.liveStatus ? 'Live' : 'Draft',
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: piece.liveStatus ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
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

    // Create set of markers including both pieces and user location
    Set<Marker> markers = {};

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

      return Marker(
        markerId: MarkerId(anchor.anchorId),
        position: LatLng(
            anchor.location.coordinates[1], anchor.location.coordinates[0]),
        infoWindow: InfoWindow(
          title: matchingPiece?.pieceTitle ?? anchor.frameName,
          snippet: 'Tap to view details',
        ),
        onTap: () {
          if (matchingPiece != null) {
            _showPiecePreview(context, matchingPiece);
          }
        },
      );
    }));

    // Add user location marker if available
    if (_currentUserLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('user_location'),
          position: _currentUserLocation!,
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
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
