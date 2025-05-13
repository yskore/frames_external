// piece_location_manager.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frames_app/core/repositories/piece_repository.dart';
import 'package:frames_app/core/services/map.dart';
import 'package:frames_app/providers/error_provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class PieceLocationManager {
  final WidgetRef ref;
  final String pieceId;
  final String pieceTitle;

  PieceLocationManager({
    required this.ref,
    required this.pieceId,
    required this.pieceTitle,
  });

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
                    Text('Piece Location', 
                         style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                          infoWindow: InfoWindow(title: pieceTitle),
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
                          MapService.openGoogleMapsNavigation(
                            anchor.location.coordinates[1],
                            anchor.location.coordinates[0],
                            ref: ref,
                          );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load piece location'))
      );
    }
  }

  Future<void> shareLocation(BuildContext context) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator()),
    );

    final pieceRepository = ref.read(pieceRepositoryProvider);
    final anchorResponse = await pieceRepository.getAnchorByPieceId(pieceId);

    // Dismiss loading indicator
    Navigator.pop(context);
    
    if (anchorResponse.error != null) {
      ref.read(errorProvider.notifier).setError(anchorResponse.error);
    }

    if (anchorResponse.data != null) {
      final anchor = anchorResponse.data!;
      
      // Format coordinates for maps
      final lat = anchor.location.coordinates[1];
      final lng = anchor.location.coordinates[0];
      final locationString = '$lat,$lng';

      // Copy to clipboard
      await Clipboard.setData(ClipboardData(text: locationString));

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not share location - anchor not found'))
      );
    }
  }
}