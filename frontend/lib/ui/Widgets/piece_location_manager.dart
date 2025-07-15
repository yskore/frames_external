// piece_location_manager.dart
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frames_app/core/mixins/message_mixin.dart';
import 'package:frames_app/core/repositories/piece_repository.dart';
import 'package:frames_app/core/services/map.dart';
import 'package:frames_app/models/piece_model.dart';
import 'package:frames_app/providers/user_provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class PieceLocationManager with MessageMixin {
  final WidgetRef ref;
  final String pieceId;
  final String pieceTitle;
  final Piece piece; // NEW: Add piece object to access hidden properties

  PieceLocationManager({
    required this.ref,
    required this.pieceId,
    required this.pieceTitle,
    required this.piece, // NEW: Required piece parameter
  });

  // NEW: Helper method to check if current user owns the piece
  bool _isCurrentUserOwner() {
    final currentUser = ref.watch(userProvider)?.username;
    return currentUser != null && currentUser == piece.pieceOwner;
  }

  // NEW: Calculate random point within radius for hidden pieces
  LatLng _getRandomLocationWithinRadius(LatLng center, int radiusMeters) {
    if (radiusMeters == 0) return center; // Use exact location if radius is 0

    final random = Random();

    // Convert radius from meters to degrees (approximate)
    final radiusDegrees =
        radiusMeters / 111000.0; // Rough conversion: 1 degree ≈ 111km

    // Generate random angle and distance
    final angle = random.nextDouble() * 2 * pi;
    final distance = random.nextDouble() * radiusDegrees;

    // Calculate new coordinates
    final lat = center.latitude + (distance * cos(angle));
    final lng = center.longitude + (distance * sin(angle));

    return LatLng(lat, lng);
  }

  // NEW: Get appropriate location based on hidden status and ownership
  LatLng _getNavigationLocation(LatLng exactLocation) {
    // If user owns the piece, always use exact location
    if (_isCurrentUserOwner()) {
      return exactLocation;
    }

    // If piece is hidden and has radius > 0, use random location within radius
    if (piece.isHidden && piece.showRadius > 0) {
      return _getRandomLocationWithinRadius(exactLocation, piece.showRadius);
    }

    // For all other cases (non-hidden or hidden with radius = 0), use exact location
    return exactLocation;
  }

  Future<void> showPieceLocationMap(BuildContext context) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final pieceRepository = ref.read(pieceRepositoryProvider);
    final anchorResponse = await pieceRepository.getAnchorByPieceId(pieceId);

    // Dismiss loading dialog
    Navigator.pop(context);

    if (anchorResponse.data != null) {
      final anchor = anchorResponse.data!;
      final exactLocation = LatLng(
          anchor.location.coordinates[1], anchor.location.coordinates[0]);

      // Determine what location to show on map
      final displayLocation = _isCurrentUserOwner()
          ? exactLocation
          : _getNavigationLocation(exactLocation);

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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Piece Location',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        // NEW: Show location type indicator
                        if (piece.isHidden && !_isCurrentUserOwner())
                          Text(
                            piece.showRadius > 0
                                ? 'Approximate location (${piece.showRadius}m area)'
                                : 'Exact location',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.orange),
                          ),
                      ],
                    ),
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
                        target: displayLocation,
                        zoom: 16,
                      ),
                      markers: {
                        Marker(
                          markerId: const MarkerId('piece_location'),
                          position: displayLocation,
                          infoWindow: InfoWindow(
                            title: pieceTitle,
                            snippet: piece.isHidden &&
                                    !_isCurrentUserOwner() &&
                                    piece.showRadius > 0
                                ? 'Approximate location'
                                : 'Piece location',
                          ),
                        )
                      },
                      // NEW: Add circle for hidden pieces with radius
                      circles: piece.isHidden &&
                              !_isCurrentUserOwner() &&
                              piece.showRadius > 0
                          ? {
                              Circle(
                                circleId: const CircleId('piece_radius'),
                                center: exactLocation,
                                radius: piece.showRadius.toDouble(),
                                fillColor: Colors.orange.withOpacity(0.2),
                                strokeColor: Colors.orange,
                                strokeWidth: 2,
                              )
                            }
                          : {},
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
                          final navigationLocation =
                              _getNavigationLocation(exactLocation);
                          MapService.openGoogleMapsNavigation(
                            navigationLocation.latitude,
                            navigationLocation.longitude,
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
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not load piece location')));
    }
  }

  Future<void> shareLocation(BuildContext context) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final pieceRepository = ref.read(pieceRepositoryProvider);
    final anchorResponse = await pieceRepository.getAnchorByPieceId(pieceId);

    // Dismiss loading indicator
    Navigator.pop(context);

    if (anchorResponse.error != null) {
      showError(anchorResponse.error);
    }

    if (anchorResponse.data != null) {
      final anchor = anchorResponse.data!;
      final exactLocation = LatLng(
          anchor.location.coordinates[1], anchor.location.coordinates[0]);

      // Determine what location to share
      final shareLocation = _getNavigationLocation(exactLocation);

      // Format coordinates for maps
      final locationString =
          '${shareLocation.latitude},${shareLocation.longitude}';

      // Copy to clipboard
      await Clipboard.setData(ClipboardData(text: locationString));

      // Show success message with instructions
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Location Copied!'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                    'The coordinates have been copied to your clipboard.'),
                const SizedBox(height: 8),
                // NEW: Show location type information
                if (piece.isHidden && !_isCurrentUserOwner()) ...[
                  Text(
                    piece.showRadius > 0
                        ? 'Note: This is an approximate location within ${piece.showRadius}m of the actual piece.'
                        : 'This is the exact piece location.',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.orange,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                const Text('To use:'),
                const Text('1. Open Google Maps or Apple Maps'),
                const Text('2. Paste the coordinates in the search bar'),
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
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Could not share location - anchor not found')));
    }
  }
}
