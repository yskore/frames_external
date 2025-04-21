import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frames_app/core/services/map.dart';
import 'package:intl/intl.dart';

class EnhancedPieceDetailsSheet extends ConsumerWidget {
  final Map<String, dynamic> arPieceData;
  final Map<String, dynamic> databaseDetails;
  
  const EnhancedPieceDetailsSheet({
    Key? key,
    required this.arPieceData,
    required this.databaseDetails,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Extract piece details from the API response
    final pieceData = databaseDetails['piece'];
    
    if (pieceData == null) {
      return _buildErrorView(context, 'Piece details not found in response');
    }
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 10),
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
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Piece title and details
                    Text(
                      pieceData['title'] ?? 'Unknown Piece',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'by ${pieceData['owner'] ?? 'Unknown Artist'}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Image
                    if (pieceData['imageUrl'] != null)
                      Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(
                            image: NetworkImage(pieceData['imageUrl']),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    
                    const SizedBox(height: 20),
                    
                    // Description
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      pieceData['description'] ?? 'No description available',
                      style: const TextStyle(fontSize: 16),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Additional details
                    const Text(
                      'Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow('Frame Type', pieceData['frameName'] ?? 'Unknown'),
                    _buildDetailRow('Created On', _formatDate(pieceData['creationDate'])),
                    _buildDetailRow('Likes', '${pieceData['likes'] ?? 0}'),
                    
                    if (pieceData['forSale'])
                      _buildDetailRow('Price', '\$${pieceData['price'] ?? 0}'),
                    
                    const SizedBox(height: 20),
                    
                    // Location section
                    if (arPieceData['latitude'] != null && arPieceData['longitude'] != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Location',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  const SizedBox(height: 12),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.favorite, color: Colors.red),
                            label: const Text('Like this Piece'),
                            onPressed: () {
                              // This will be implemented later
                              
                            },
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 48),
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.share_location),
                            label: const Text('Share Location'),
                            onPressed: () {
                              _shareLocation(
                                context,
                                arPieceData['latitude'], 
                                arPieceData['longitude']
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 48),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            
            // Close button
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic dateValue) {
    try {
      if (dateValue == null) return 'Unknown';
      
      DateTime date;
      if (dateValue is String) {
        date = DateTime.parse(dateValue);
      } else if (dateValue is Map && dateValue['\$date'] != null) {
        // Handle MongoDB date format
        int timestamp = int.parse(dateValue['\$date']['\$numberLong']);
        date = DateTime.fromMillisecondsSinceEpoch(timestamp);
      } else {
        return 'Unknown format';
      }
      
      return DateFormat('MMM d, yyyy').format(date);
    } catch (e) {
      print('Error formatting date: $e');
      return 'Invalid date';
    }
  }

  void _shareLocation(BuildContext context, double lat, double lng) async {
    try {
      // Format coordinates for maps
      final locationString = '$lat,$lng';

      // Copy to clipboard
      await Clipboard.setData(ClipboardData(text: locationString));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location copied to clipboard')),
      );
    } catch (e) {
      print('Error sharing location: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to share location')),
        );
      }
    }
  }

  Widget _buildErrorView(BuildContext context, String message) {
    return Container(
      height: 300,
      decoration: const BoxDecoration(
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
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(message),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}