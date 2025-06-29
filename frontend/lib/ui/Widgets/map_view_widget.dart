import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frames_app/Providers/user_provider.dart';
import 'package:frames_app/core/repositories/anchor_repository.dart';
import 'package:frames_app/core/repositories/piece_repository.dart';
import 'package:frames_app/models/anchor_model.dart';
import 'package:frames_app/models/piece_model.dart';
import 'package:frames_app/ui/Widgets/piece_preview_popup.dart';
import 'package:frames_app/core/services/map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// Providers for map state - using family providers to support multiple instances
final mapAnchorsProvider = StateProvider.family<List<AnchorModel>, String>((ref, key) => []);
final mapLoadingProvider = StateProvider.family<bool, String>((ref, key) => false);
final mapRadiusProvider = StateProvider.family<double, String>((ref, key) => 5000.0);
final mapErrorProvider = StateProvider.family<String?, String>((ref, key) => null);
final selectedMarkerProvider = StateProvider.family<String?, String>((ref, key) => null);
final markerPieceDetailsProvider = StateProvider.family<Piece?, String>((ref, key) => null);
final mapPiecesProvider = StateProvider.family<Map<String, Piece>, String>((ref, key) => {});


enum MapMode {
  allAnchors,     // Show all anchored pieces globally
  userAnchors,    // Show anchors for a specific user
  explore,        // Explore mode with custom info widgets
}

class MapViewWidget extends ConsumerStatefulWidget {
  final MapMode mode;
  final String? username; // Required when mode is userAnchors
  final List<AnchorModel>? preloadedAnchors; // For user profile screen
  final List<Piece>? preloadedPieces; // For user profile screen
  final String mapKey; // Unique key for this map instance

  const MapViewWidget({
    super.key,
    required this.mode,
    required this.mapKey,
    this.username,
    this.preloadedAnchors,
    this.preloadedPieces,
  }) : assert(
          mode == MapMode.userAnchors ? username != null : true,
          'Username is required when mode is userAnchors',
        );

  @override
  ConsumerState<MapViewWidget> createState() => _MapViewWidgetState();
}

class _MapViewWidgetState extends ConsumerState<MapViewWidget> {
  Completer<GoogleMapController> _mapController = Completer();
  LatLng? _currentUserLocation;
  bool _mapInitialized = false;
  Timer? _radiusExpansionTimer;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  @override
  void dispose() {
    _radiusExpansionTimer?.cancel();
    _disposeMapController();
    super.dispose();
  }

  Future<void> _initializeMap() async {
    if (_mapInitialized) return;
    
    setState(() {
      _mapInitialized = true;
    });

    await _requestLocationPermission();
    await _loadAnchors();
  }

  Future<void> _requestLocationPermission() async {
    final permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      await _getCurrentLocation();
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
      ref.read(mapErrorProvider(widget.mapKey).notifier).state = 'Failed to get location: $e';
    }
  }

Future<void> _loadAnchors() async {
  ref.read(mapLoadingProvider(widget.mapKey).notifier).state = true;
  ref.read(mapErrorProvider(widget.mapKey).notifier).state = null;

  try {
    List<AnchorModel> anchors = [];
    Map<String, Piece> pieces = {};

    if (widget.mode == MapMode.userAnchors && widget.preloadedAnchors != null) {
      // Use preloaded data
      anchors = widget.preloadedAnchors!;
      if (widget.preloadedPieces != null) {
        for (final piece in widget.preloadedPieces!) {
          pieces[piece.pieceid] = piece;
        }
      }
    } else if ((widget.mode == MapMode.allAnchors || widget.mode == MapMode.explore) && _currentUserLocation != null) {
      // Fetch nearby anchors
      final anchorRepository = ref.read(anchorRepositoryProvider);
      final currentRadius = ref.read(mapRadiusProvider(widget.mapKey));
      
      final result = await anchorRepository.fetchNearbyAnchors(currentRadius);
      
      if (result.error == null && result.data != null) {
        anchors = result.data!;
        
        // Fetch piece details for each anchor
        final pieceRepository = ref.read(pieceRepositoryProvider);
        for (final anchor in anchors) {
          try {
            final pieceResponse = await pieceRepository.getPieceById(anchor.pieceId);
            if (pieceResponse.isSuccess && pieceResponse.data != null) {
              final piece = Piece.fromJson(pieceResponse.data!['piece']);
              pieces[piece.pieceid] = piece;
            }
          } catch (e) {
            print('Failed to fetch piece ${anchor.pieceId}: $e');
          }
        }
      } else {
        ref.read(mapErrorProvider(widget.mapKey).notifier).state = result.error ?? 'Failed to load anchors';
        return;
      }
    }

    // Update both providers
    ref.read(mapAnchorsProvider(widget.mapKey).notifier).state = anchors;
    ref.read(mapPiecesProvider(widget.mapKey).notifier).state = pieces;
    
  } catch (e) {
    print('Error loading anchors: $e');
    ref.read(mapErrorProvider(widget.mapKey).notifier).state = 'Error loading anchors: $e';
  } finally {
    ref.read(mapLoadingProvider(widget.mapKey).notifier).state = false;
  }
}

    bool _isCurrentUserOwner(String pieceOwner) {
    final currentUser = ref.watch(userProvider)?.username;
    return currentUser != null && currentUser == pieceOwner;
  }



  Future<void> _expandSearchRadius() async {
    if (widget.mode != MapMode.allAnchors && widget.mode != MapMode.explore) return; // Only allow expansion for global search and explore
    
    final currentRadius = ref.read(mapRadiusProvider(widget.mapKey));
    final newRadius = currentRadius * 2; // Double the radius
    
    if (newRadius > 50000) return; // Max 50km radius
    
    ref.read(mapRadiusProvider(widget.mapKey).notifier).state = newRadius;
    await _loadAnchors();
  }

  Future<void> _handleMarkerTap(AnchorModel anchor) async {
    if (widget.mode == MapMode.explore) {
      // For explore mode, show custom info widget
      await _showPieceInfoWidget(anchor);
    } else {
      // For other modes, show piece preview
      await _showPiecePreviewFromAnchor(anchor);
    }
  }

  Future<void> _showPieceInfoWidget(AnchorModel anchor) async {
    try {
      // Set selected marker
      ref.read(selectedMarkerProvider(widget.mapKey).notifier).state = anchor.anchorId;
      
      // Show loading state
      ref.read(markerPieceDetailsProvider(widget.mapKey).notifier).state = null;
      
      // Fetch piece details
      final pieceRepository = ref.read(pieceRepositoryProvider);
      final pieceResponse = await pieceRepository.getPieceById(anchor.pieceId);

      if (pieceResponse.isSuccess && pieceResponse.data != null) {
        final piece = Piece.fromJson(pieceResponse.data!['piece']);
        ref.read(markerPieceDetailsProvider(widget.mapKey).notifier).state = piece;
      } else {
        // Clear selection on error
        ref.read(selectedMarkerProvider(widget.mapKey).notifier).state = null;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load piece details: ${pieceResponse.message}')),
        );
      }
    } catch (e) {
      print('Error showing piece info: $e');
      ref.read(selectedMarkerProvider(widget.mapKey).notifier).state = null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading piece: $e')),
      );
    }
  }

  Future<void> _showPiecePreviewFromAnchor(AnchorModel anchor) async {
    try {
    final pieces = ref.read(mapPiecesProvider(widget.mapKey));
    Piece? piece = pieces[anchor.pieceId];

    // If no cached piece, fetch from API
    if (piece == null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final pieceRepository = ref.read(pieceRepositoryProvider);
      final pieceResponse = await pieceRepository.getPieceById(anchor.pieceId);

      Navigator.of(context).pop();

      if (pieceResponse.isSuccess && pieceResponse.data != null) {
        piece = Piece.fromJson(pieceResponse.data!['piece']);
        // Cache the piece
        final updatedPieces = Map<String, Piece>.from(pieces);
        updatedPieces[piece.pieceid] = piece;
        ref.read(mapPiecesProvider(widget.mapKey).notifier).state = updatedPieces;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load piece details: ${pieceResponse.message}')),
        );
        return;
      }
    }

      // Show piece preview
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
            piece: piece!,
            pieceData: pieceData,
            isReadOnly: widget.mode == MapMode.allAnchors || widget.mode == MapMode.explore, // Read-only for global search and explore
            onPieceUpdated: () {
              // Refresh data if needed
              _loadAnchors();
            },
          );
        },
      );
    } catch (e) {
      // Close loading dialog if still open
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      print('Error showing piece preview: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading piece: $e')),
      );
    }
  }

  void _disposeMapController() async {
    if (_mapController.isCompleted) {
      final controller = await _mapController.future;
      controller.dispose();
      _mapController = Completer<GoogleMapController>();
    }
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

  void _closeInfoWidget() {
    ref.read(selectedMarkerProvider(widget.mapKey).notifier).state = null;
    ref.read(markerPieceDetailsProvider(widget.mapKey).notifier).state = null;
  }

  @override
Widget build(BuildContext context) {
  final anchors = ref.watch(mapAnchorsProvider(widget.mapKey));
  final pieces = ref.watch(mapPiecesProvider(widget.mapKey));
  final isLoading = ref.watch(mapLoadingProvider(widget.mapKey));
  final error = ref.watch(mapErrorProvider(widget.mapKey));
  final currentRadius = ref.watch(mapRadiusProvider(widget.mapKey));
  final selectedMarkerId = ref.watch(selectedMarkerProvider(widget.mapKey));
  final selectedPieceDetails = ref.watch(markerPieceDetailsProvider(widget.mapKey));

  if (error != null) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
          const SizedBox(height: 16),
          Text(error, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadAnchors,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  if (!_mapInitialized || 
      ((widget.mode == MapMode.allAnchors || widget.mode == MapMode.explore) && _currentUserLocation == null)) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Initializing map...'),
        ],
      ),
    );
  }

  if (anchors.isEmpty && !isLoading) {
    String message;
    Widget? actionButton;

    if (widget.mode == MapMode.userAnchors) {
      message = 'No live pieces placed on map';
    } else {
      message = 'No pieces found within ${(currentRadius / 1000).toStringAsFixed(1)}km';
      if (currentRadius < 50000) {
        actionButton = ElevatedButton(
          onPressed: _expandSearchRadius,
          child: Text('Search wider area (${((currentRadius * 2) / 1000).toStringAsFixed(1)}km)'),
        );
      }
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          if (actionButton != null) ...[
            const SizedBox(height: 16),
            actionButton,
          ],
        ],
      ),
    );
  }

  // Create markers and circles from anchors
  Set<Marker> markers = {};
  Set<Circle> circles = {};

  for (final anchor in anchors) {
    final piece = pieces[anchor.pieceId];
    
    // Determine if this is a hidden piece and how to display it
    final isHidden = piece?.isHidden ?? false;
    final showRadius = piece?.showRadius ?? 0;
    final isOwner = piece != null ? _isCurrentUserOwner(piece.pieceOwner) : false;

    final position = LatLng(
      anchor.location.coordinates[1], // latitude
      anchor.location.coordinates[0], // longitude
    );

    if (isHidden && !isOwner && showRadius > 0) {
      // For non-owners viewing hidden pieces with radius > 0: show as circle
      circles.add(
        Circle(
          circleId: CircleId('hidden_${anchor.anchorId}'),
          center: position,
          radius: showRadius.toDouble(),
          fillColor: Colors.orange.withOpacity(0.2),
          strokeColor: Colors.orange,
          strokeWidth: 2,
          onTap: () => _handleMarkerTap(anchor),
        ),
      );
    } else {
      // For all other cases: show as normal marker
      markers.add(
        Marker(
          markerId: MarkerId(anchor.anchorId),
          position: position,
          infoWindow: InfoWindow(
            title: piece?.pieceTitle ?? anchor.frameName,
            snippet: widget.mode == MapMode.allAnchors 
                ? 'By ${piece?.pieceOwner ?? anchor.pieceOwner} • Tap to view'
                : widget.mode == MapMode.explore
                    ? 'Tap for details'
                    : 'Tap to view details',
          ),
          onTap: () => _handleMarkerTap(anchor),
          icon: isHidden && isOwner 
              ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange)
              : BitmapDescriptor.defaultMarker,
        ),
      );
    }
  }

  // Add user location marker
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
          : const LatLng(0, 0));

  return Stack(
    children: [
      GoogleMap(
        initialCameraPosition: CameraPosition(
          target: initialPosition,
          zoom: widget.mode == MapMode.userAnchors ? 15 : 13,
        ),
        markers: markers,
        circles: circles,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        mapToolbarEnabled: false,
        zoomControlsEnabled: true,
        onMapCreated: (GoogleMapController controller) {
          if (!_mapController.isCompleted) {
            _mapController.complete(controller);
            if (markers.isNotEmpty && widget.mode == MapMode.userAnchors) {
              _fitBounds(markers);
            }
          }
        },
        onCameraMove: (CameraPosition position) {
          // Cancel existing timer
          _radiusExpansionTimer?.cancel();
          
          // Set new timer for lazy loading when user stops moving
          _radiusExpansionTimer = Timer(const Duration(seconds: 2), () {
            // Could implement region-based loading here if needed
          });
        },
        onTap: (LatLng position) {
          // Close info widget when tapping elsewhere on the map
          if (widget.mode == MapMode.explore) {
            _closeInfoWidget();
          }
        },
      ),
      
      // Loading overlay
      if (isLoading)
        Container(
          color: Colors.black26,
          child: const Center(
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text('Loading pieces...'),
                  ],
                ),
              ),
            ),
          ),
        ),
        
      // Info panel (only for global search and explore)
      if (widget.mode == MapMode.allAnchors || widget.mode == MapMode.explore)
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${anchors.length} pieces within ${(currentRadius / 1000).toStringAsFixed(1)}km',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  if (currentRadius < 50000)
                    TextButton(
                      onPressed: _expandSearchRadius,
                      child: const Text('Expand'),
                    ),
                ],
              ),
            ),
          ),
        ),

      // Custom info widget for explore mode
      if (widget.mode == MapMode.explore && selectedMarkerId != null)
        _buildCustomInfoWidget(selectedMarkerId, selectedPieceDetails, anchors),
    ],
  );
}

  Widget _buildCustomInfoWidget(String selectedMarkerId, Piece? pieceDetails, List<AnchorModel> anchors) {
    // Find the selected anchor
    final selectedAnchor = anchors.firstWhere(
      (anchor) => anchor.anchorId == selectedMarkerId,
      orElse: () => anchors.first, // Fallback
    );

    return Positioned(
      bottom: 100,
      left: 16,
      right: 16,
      child: Card(
        elevation: 8,
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with close button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      pieceDetails?.pieceTitle ?? selectedAnchor.frameName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: _closeInfoWidget,
                    icon: const Icon(Icons.close),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              if (pieceDetails != null) ...[
                // Piece owner
                Text(
                  'By ${pieceDetails.pieceOwner}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Stats row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      Icons.favorite,
                      pieceDetails.pieceLikes.toString(),
                      'Likes',
                      Colors.red,
                    ),
                    _buildStatItem(
                      Icons.visibility,
                      pieceDetails.pieceImpressions.toString(),
                      'Views',
                      Colors.blue,
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Creation date
                Text(
                  'Created: ${_formatDate(pieceDetails.pieceCreationDate)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Get Directions button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final lat = selectedAnchor.location.coordinates[1];
                      final lng = selectedAnchor.location.coordinates[0];
                      
                      MapService.openGoogleMapsNavigation(
                        lat,
                        lng,
                        context: context,
                      ).then((success) {
                        if (!success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Could not open navigation'),
                            ),
                          );
                        }
                      });
                    },
                    icon: const Icon(Icons.directions),
                    label: const Text('Get Directions'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ] else ...[
                // Loading state
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';
    
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} year${(difference.inDays / 365).floor() == 1 ? '' : 's'} ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} month${(difference.inDays / 30).floor() == 1 ? '' : 's'} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else {
      return 'Today';
    }
  }
}