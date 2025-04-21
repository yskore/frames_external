import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frames_app/core/services/map.dart';

class PieceInteractionWidget extends ConsumerWidget {
  final String pieceData;
  final VoidCallback onClose;
  final VoidCallback? onViewDetails;

  const PieceInteractionWidget({
    Key? key,
    required this.pieceData,
    required this.onClose,
    this.onViewDetails,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Parse the piece data with error handling
    Map<String, dynamic> pieceJson;
    try {
      pieceJson = jsonDecode(pieceData);
    } catch (e) {
      print('Error parsing piece data: $e');
      return _buildErrorWidget(context);
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10.0,
            spreadRadius: 0.0,
          )
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: EdgeInsets.only(top: 10),
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            
            // Piece information
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      pieceJson['frameName'] ?? 'Unknown Piece',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    SizedBox(height: 16),
                    
                    // Image if available
                    if (pieceJson['imageUrl'] != null)
                      Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(
                            image: NetworkImage(pieceJson['imageUrl']),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    
                    SizedBox(height: 16),
                    
                    // Action buttons row: Like and Get Directions
                    Row(
                      children: [
                        // Like button
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: Icon(Icons.favorite, color: Colors.red),
                            label: Text('Like'),
                            onPressed: () {
                              // This will be implemented later
                              print('Like functionality will be implemented later');
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Like functionality coming soon!')),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        
                        SizedBox(width: 8),
                        
                        // Get Directions button
                        if (pieceJson['latitude'] != null && pieceJson['longitude'] != null)
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: Icon(Icons.directions),
                              label: Text('Directions'),
                              onPressed: () {
                                try {
                                  // Use MapService to navigate
                                  MapService.openGoogleMapsNavigation(
                                    pieceJson['latitude'],
                                    pieceJson['longitude'],
                                    ref: ref,
                                  );
                                } catch (e) {
                                  print('Error opening maps: $e');
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Could not open maps')),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                      ],
                    ),
                    
                    // Additional information sections
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // IDs
                          if (pieceJson['pieceid'] != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                'Piece ID: ${pieceJson['pieceid']}',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ),

                          // Anchor information if available
                          if (pieceJson['anchorId'] != null) 
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                'Anchor ID: ${pieceJson['anchorId']}',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Action buttons
            Padding(
              padding: EdgeInsets.all(16),
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: onClose,
                      child: Text('Close'),
                    ),
                    if (onViewDetails != null)
                      ElevatedButton(
                        onPressed: onViewDetails,
                        child: Text('More Details'),
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

  Widget _buildErrorWidget(BuildContext context) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 48),
            SizedBox(height: 16),
            Text('Error loading piece information'),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: onClose,
              child: Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}