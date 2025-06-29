import 'dart:convert';
import 'dart:developer';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frames_app/core/services/unity_scene_service.dart';
import 'package:frames_app/models/piece_model.dart';
import 'package:frames_app/models/user_profile_model.dart';
import 'package:frames_app/models/anchor_model.dart';
import 'package:frames_app/core/repositories/piece_repository.dart';
import 'package:frames_app/ui/Screens/home_screen.dart';
import 'package:frames_app/ui/Screens/search_screen.dart';
import 'package:frames_app/ui/Widgets/piece_preview_popup.dart';
import 'package:frames_app/Providers/error_provider.dart';
import 'package:frames_app/Providers/user_provider.dart';
import 'package:frames_app/Providers/subscription_provider.dart';
import 'package:frames_app/ui/Screens/user_subscribers_screen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frames_app/core/services/unity_scene_service.dart';
import 'package:frames_app/models/piece_model.dart';
import 'package:frames_app/models/user_profile_model.dart';
import 'package:frames_app/models/anchor_model.dart';
import 'package:frames_app/ui/Screens/home_screen.dart';
import 'package:frames_app/ui/Screens/search_screen.dart';
import 'package:frames_app/ui/Widgets/piece_preview_popup.dart';
import 'package:frames_app/ui/Widgets/map_view_widget.dart';
import 'package:frames_app/Providers/error_provider.dart';
import 'package:frames_app/Providers/user_provider.dart';
import 'package:frames_app/Providers/subscription_provider.dart';
import 'package:frames_app/ui/Screens/user_subscribers_screen.dart';

class OtherUserProfileScreen extends ConsumerStatefulWidget {
  final String username;

  const OtherUserProfileScreen({
    super.key,
    required this.username,
  });

  @override
  ConsumerState<OtherUserProfileScreen> createState() =>
      _OtherUserProfileScreenState();
}

class _OtherUserProfileScreenState
    extends ConsumerState<OtherUserProfileScreen> {
  bool _isLoading = true;
  bool _showGallery = true; // New state variable for toggle
  UserProfileModel? _userProfile;
  List<Piece>? _pieces;
  List<AnchorModel>? _anchors;
  String? _errorMessage;
  bool _isSubscribed = false;
  bool _isSubscribeButtonLoading = false;
  
  Completer<GoogleMapController> _mapController = Completer();
  LatLng? _currentUserLocation;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
    _requestLocationPermission();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sceneManager = ref.read(unitySceneManagerProvider);
      if (sceneManager.isUnityInitialized) {
        sceneManager.loadScene(UnitySceneType.previewScene);
      }
    });
  }

  Future<void> _requestLocationPermission() async {
    final permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      try {
        final position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);
        setState(() {
          _currentUserLocation = LatLng(position.latitude, position.longitude);
        });
      } catch (e) {
        print('Error getting location: $e');
      }
    }
  }

  Future<void> _loadAnchors() async {
    if (_pieces == null) return;
    
    final pieceRepository = ref.read(pieceRepositoryProvider);
    final anchors = <AnchorModel>[];
    
    for (final piece in _pieces!.where((p) => p.liveStatus)) {
      final result = await pieceRepository.getAnchorByPieceId(piece.pieceid);
      if (result.error == null && result.data != null) {
        anchors.add(result.data!);
      }
    }
    
    if (mounted) {
      setState(() {
        _anchors = anchors;
      });
    }
  }

  Future<void> _loadProfileData() async {
    try {
      final userNotifier = ref.read(userProvider.notifier);
      final response = await userNotifier.getProfileWithPieces(widget.username);

      log(response.toString());
      log('Response: ${response.message}');

      if (response.isSuccess && response.data != null) {
        setState(() {
          _userProfile = UserProfileModel.fromJson(response.data!['profile']);
          _pieces = (response.data!['pieces'] as List)
              .map((piece) => Piece.fromJson(piece))
              .toList();
          
          // Initialize empty anchors list
          _anchors = [];
          _isSubscribed = response.data!['isSubscribed'] ?? false;
          _isLoading = false;
          
          // Fetch anchors for live pieces
          _loadAnchors();
        });
      } else {
        setState(() {
          _errorMessage = response.message ?? 'Failed to load user profile';
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      log('Error loading profile data: $e $stackTrace');

      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _navigateBackToHome() {
    // Pre-load AR scene before navigation
    final sceneManager = ref.read(unitySceneManagerProvider);
    if (sceneManager.isUnityInitialized) {
      sceneManager.loadScene(UnitySceneType.arScene).then((_) {
        if (!mounted) return;
        Navigator.of(context).pop();
      });
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _disposeMapController();
    super.dispose();
  }

  void _disposeMapController() async {
    if (_mapController.isCompleted) {
      final controller = await _mapController.future;
      controller.dispose();
      _mapController = Completer<GoogleMapController>();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _navigateBackToHome();
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.username),
          leading: IconButton(
            icon: const BackButtonIcon(),
            onPressed: () {
              _navigateBackToHome();
            },
          ),
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                'Failed to load profile: $_errorMessage',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _navigateBackToHome, 
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    } else {
      return SafeArea(
        child: Column(
          children: [
            _buildProfileInfoRow(context, _userProfile!),
            const Divider(),
            _buildToggleRow(), // Add the toggle row
            Expanded(
              child: _showGallery
                  ? _buildGalleryView(context, ref, _pieces!)
                  : _buildMapView(), // Show map or gallery based on toggle
            ),
          ],
        ),
      );
    }
  }

  // New toggle row widget (similar to user profile screen)
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

  Widget _buildMapView() {
    if (_anchors == null || _anchors!.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No live pieces placed on map', 
                 style: TextStyle(fontSize: 18, color: Colors.grey)),
            SizedBox(height: 8),
            Text('This user hasn\'t placed any pieces yet',
                 style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    Set<Marker> markers = {};
    Set<Circle> circles = {}; // NEW: Add circles for hidden pieces
    
    // Add piece markers with hidden piece filtering
    for (final anchor in _anchors!) {
      final piece = _pieces!.firstWhere((p) => p.pieceid == anchor.pieceId);
      
      // Skip completely hidden pieces (isHidden = true, showRadius = 0)
      // For other hidden pieces, show according to the radius rules
      final isHidden = piece.isHidden;
      final showRadius = piece.showRadius;
      
      final position = LatLng(
        anchor.location.coordinates[1], 
        anchor.location.coordinates[0]
      );
      
      if (isHidden && showRadius > 0) {
        // Hidden piece with radius > 0: show as circle for non-owners
        circles.add(
          Circle(
            circleId: CircleId('hidden_${anchor.anchorId}'),
            center: position,
            radius: showRadius.toDouble(),
            fillColor: Colors.orange.withOpacity(0.2),
            strokeColor: Colors.orange,
            strokeWidth: 2,
            onTap: () => _showPiecePreview(context, piece),
          ),
        );
      } else {
        // All other cases: show as normal marker
        // This includes:
        // - Non-hidden pieces (normal marker)
        // - Hidden pieces with radius = 0 (exact location marker)
        markers.add(
          Marker(
            markerId: MarkerId(anchor.anchorId),
            position: position,
            infoWindow: InfoWindow(
              title: piece.pieceTitle, 
              snippet: 'Tap to view'
            ),
            onTap: () => _showPiecePreview(context, piece),
          ),
        );
      }
    }
    
    // Add user location
    if (_currentUserLocation != null) {
      markers.add(Marker(
        markerId: const MarkerId('user_location'),
        position: _currentUserLocation!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: 'Your Location'),
      ));
    }

    final initialPosition = _currentUserLocation ?? 
        LatLng(_anchors!.first.location.coordinates[1], _anchors!.first.location.coordinates[0]);

    return GoogleMap(
      initialCameraPosition: CameraPosition(target: initialPosition, zoom: 15),
      markers: markers,
      circles: circles, // NEW: Add circles for hidden pieces
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      onMapCreated: (controller) {
        if (!_mapController.isCompleted) {
          _mapController.complete(controller);
          if (markers.isNotEmpty) _fitBounds(markers);
        }
      },
    );
  }

  Future<void> _fitBounds(Set<Marker> markers) async {
    if (markers.isEmpty) return;
    double minLat = markers.first.position.latitude;
    double maxLat = markers.first.position.latitude;
    double minLng = markers.first.position.longitude;
    double maxLng = markers.first.position.longitude;

    for (final marker in markers) {
      if (marker.position.latitude < minLat) minLat = marker.position.latitude;
      if (marker.position.latitude > maxLat) maxLat = marker.position.latitude;
      if (marker.position.longitude < minLng) minLng = marker.position.longitude;
      if (marker.position.longitude > maxLng) maxLng = marker.position.longitude;
    }

    final controller = await _mapController.future;
    controller.animateCamera(CameraUpdate.newLatLngBounds(
      LatLngBounds(southwest: LatLng(minLat, minLng), northeast: LatLng(maxLat, maxLng)),
      50,
    ));
  }



  Widget _buildProfileInfoRow(
      BuildContext context, UserProfileModel userProfile) {

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: userProfile.Profile_photo.isNotEmpty
                      ? NetworkImage(userProfile.Profile_photo)
                      : const NetworkImage('https://dummyimage.com/250/ffffff'),
                ),
                Text(
                  userProfile.username,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 4),
                Text(
                  userProfile.bio,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildCountColumn(
                        'Subscribers', userProfile.subscriberCount.toString()),
                    _buildCountColumn(
                        'Impressions', userProfile.totalImpressions.toString()),
                    _buildCountColumn(
                        'Live Pieces', userProfile.live_pieces.toString()),
                  ],
                ),
                const SizedBox(height: 12),
                _buildSubscribeButton(userProfile.username),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscribeButton(String username) {
    return ElevatedButton(
      onPressed: _isSubscribeButtonLoading
          ? null
          : () => _toggleSubscription(username),
      style: ElevatedButton.styleFrom(
        backgroundColor:
            _isSubscribed ? Colors.grey[300] : Theme.of(context).primaryColor,
        foregroundColor: _isSubscribed ? Colors.black : Colors.white,
        minimumSize: const Size(double.infinity, 40),
      ),
      child: _isSubscribeButtonLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(_isSubscribed ? 'Unsubscribe' : 'Subscribe'),
    );
  }

  Future<void> _toggleSubscription(String username) async {
    final subscriptionsNotifier = ref.read(subscriptionsProvider.notifier);
    final messageNotifier = ref.read(messageProvider.notifier);
    bool success;

    setState(() {
      _isSubscribeButtonLoading = true;
    });

    if (_isSubscribed) {
      // Unsubscribe
      success = await subscriptionsNotifier.unsubscribeFromUser(username);
      if (success) {
        setState(() {
          _isSubscribed = false;
          _userProfile = _userProfile?.copyWith(
            subscriberCount: _userProfile!.subscriberCount - 1,
          );
        });
      }
    } else {
      // Subscribe
      success = await subscriptionsNotifier.subscribeToUser(username);
      if (success) {
        setState(() {
          _isSubscribed = true;
          _userProfile = _userProfile?.copyWith(
            subscriberCount: _userProfile!.subscriberCount + 1,
          );
        });
      }
    }

    setState(() {
      _isSubscribeButtonLoading = false;
    });

    if (success) {
      messageNotifier.setInfo(
        _isSubscribed
            ? 'Subscribed to $username'
            : 'Unsubscribed from $username',
      );
    }
  }

  Widget _buildCountColumn(String label, String count) {
    final bool isSubscribers = label == 'Subscribers';

    return GestureDetector(
      onTap: isSubscribers && int.parse(count) > 0
          ? () => _navigateToSubscribers()
          : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            count,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isSubscribers && int.parse(count) > 0
                  ? Theme.of(context).primaryColor
                  : null,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isSubscribers && int.parse(count) > 0
                  ? Theme.of(context).primaryColor
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToSubscribers() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => UserSubscribersScreen(
          username: widget.username,
          displayName: _userProfile!.username,
        ),
      ),
    );
  }

 
  Widget _buildGalleryView(BuildContext context, WidgetRef ref, List<Piece> pieces) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Filter out hidden pieces for other users' profiles
    final visiblePieces = pieces.where((piece) => !piece.isHidden).toList();

    if (visiblePieces.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No pieces to display',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'This user hasn\'t shared any visible pieces yet',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1,
      ),
      itemCount: visiblePieces.length,
      itemBuilder: (context, index) {
        return _buildPieceItem(context, ref, visiblePieces[index]); // Fixed: pass all three parameters
      },
    );
  }

  Widget _buildPieceItem(BuildContext context, WidgetRef ref, Piece piece) {
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

  void _showPiecePreview(BuildContext context, Piece piece) {
    String pieceData = jsonEncode({
      'frameName': piece.frameName,
      'faceName': 'Face',
      'imageUrl': piece.pieceDisplay,
      'PieceID': piece.pieceid,
    });

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return PiecePreviewPopup(
          piece: piece,
          pieceData: pieceData,
          onPieceUpdated: () {
            // Refresh the profile data when a piece is updated
            _loadProfileData();
          },
          isReadOnly: true,  
        );
      },
    );
  }
}