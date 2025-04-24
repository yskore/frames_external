import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frames_app/Providers/like_provider.dart';
import 'package:frames_app/Providers/impression_provider.dart';
import 'package:frames_app/core/services/map.dart';
import 'package:intl/intl.dart';
import 'package:frames_app/core/repositories/piece_repository.dart';

class EnhancedPieceDetailsSheet extends ConsumerStatefulWidget {
  final Map<String, dynamic> arPieceData;
  final Map<String, dynamic> databaseDetails;
  
  const EnhancedPieceDetailsSheet({
    Key? key,
    required this.arPieceData,
    required this.databaseDetails,
  }) : super(key: key);
  
  @override
  ConsumerState<EnhancedPieceDetailsSheet> createState() => _EnhancedPieceDetailsSheetState();
}

class _EnhancedPieceDetailsSheetState extends ConsumerState<EnhancedPieceDetailsSheet> with SingleTickerProviderStateMixin {
  String? pieceId;
  bool _isAnimatingLike = false;
  late AnimationController _likeAnimationController;
  late Animation<double> _likeAnimation;
  bool _impressionRecorded = false;
  int _impressionCount = 0;
  
  @override
  void initState() {
    super.initState();
    _extractPieceId();
    _checkLikeStatus();
    _recordImpression();
    
    // Set up heart animation
    _likeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _likeAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.3)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.3, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
    ]).animate(_likeAnimationController);
  }
  
  @override
  void dispose() {
    _likeAnimationController.dispose();
    super.dispose();
  }
  
  void _extractPieceId() {
    // Extract piece ID from database details
    final pieceData = widget.databaseDetails['piece'];
    if (pieceData != null) {
      pieceId = pieceData['id'];
      
      // Initialize like count if available
      if (pieceId != null && pieceData['likes'] != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(pieceLikeCountProvider(pieceId!).notifier).state = pieceData['likes'];
        });
      }

      // Initialize impression count
      if (pieceData['Piece_impressions'] != null) {
        setState(() {
          _impressionCount = pieceData['Piece_impressions'];
        });
      }
    }
  }
  
  void _checkLikeStatus() {
    if (pieceId != null) {
      // Wait for the widget to be built before checking
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(likeNotifierProvider).checkLikeStatus(pieceId!);
      });
    }
  }

  void _recordImpression() {
    if (pieceId != null && !_impressionRecorded) {
      _impressionRecorded = true;
      
      // Increment the local impression count for immediate feedback
      setState(() {
        _impressionCount += 1;
      });
      
      // Record the impression in the backend
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(pieceRepositoryProvider).incrementImpressions(pieceId!).then((response) {
          if (response.isSuccess && response.data != null && response.data!['impressions'] != null) {
            // Update with the server's count if available
            setState(() {
              _impressionCount = response.data!['impressions'];
            });
          }
        });
      });
    }
  }

  Future<void> _handleLikeToggle() async {
    if (pieceId == null) return;
    
    setState(() {
      _isAnimatingLike = true;
    });
    
    try {
      final success = await ref.read(likeNotifierProvider).toggleLike(
        pieceId!,
        showLoading: false,
      );
      
      if (success && mounted) {
        // Animate heart if successful
        _likeAnimationController.forward(from: 0.0);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAnimatingLike = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // If piece ID exists, watch the like status and count from providers
    final bool isLiked = pieceId != null ? 
      ref.watch(currentPieceLikeStatusProvider(pieceId!)) : false;
    
    final int likeCount = pieceId != null ? 
      ref.watch(pieceLikeCountProvider(pieceId!)) : 0;
    
    // Extract piece details from the API response
    final pieceData = widget.databaseDetails['piece'];
    print('TEST: Piece data: $pieceData');
    // Extract anchor details if available
    final anchorData = widget.databaseDetails['anchor'];
    
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
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
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
                          // Like indicator overlay
                          Positioned(
                            bottom: 12,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.favorite, color: Colors.red, size: 18),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$likeCount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
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
                    _buildDetailRow('Likes', '$likeCount'),
                    _buildDetailRow('Views', pieceData['impressions']?.toString() ?? '0'),
                    
                    // Stats indicator with icons
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          // Views indicator
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.visibility, color: Colors.blue),
                                  const SizedBox(width: 8),
                                  Text(
                                    pieceData['impressions']?.toString() ?? '0',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Likes indicator
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.favorite, color: Colors.red),
                                  const SizedBox(width: 8),
                                  Text(
                                    '$likeCount',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    if (pieceData['forSale'])
                      _buildDetailRow('Price', '\$${pieceData['price'] ?? 0}'),
                    
                    // Add Expiry Time information if available
                    if (anchorData != null && anchorData['expireTime'] != null)
                      _buildExpiryTimeInfo(anchorData['expireTime']),
                    
                    const SizedBox(height: 20),
                    
                    // Location and like actions
                    if (widget.arPieceData['latitude'] != null && widget.arPieceData['longitude'] != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Actions',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Like button
                          ElevatedButton.icon(
                            icon: AnimatedBuilder(
                              animation: _likeAnimation,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _likeAnimation.value,
                                  child: _isAnimatingLike
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                                        ),
                                      )
                                    : Icon(
                                        isLiked ? Icons.favorite : Icons.favorite_border,
                                        color: Colors.red,
                                      ),
                                );
                              },
                            ),
                            label: Text(isLiked ? 'Liked' : 'Like this Piece'),
                            onPressed: _isAnimatingLike ? null : _handleLikeToggle,
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 48),
                              backgroundColor: isLiked ? Colors.red.withOpacity(0.1) : null,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.share_location),
                            label: const Text('Share Location'),
                            onPressed: () {
                              _shareLocation(
                                context,
                                widget.arPieceData['latitude'], 
                                widget.arPieceData['longitude']
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 48),
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.directions),
                            label: const Text('Get Directions'),
                            onPressed: () {
                              MapService.openGoogleMapsNavigation(
                                widget.arPieceData['latitude'],
                                widget.arPieceData['longitude'],
                                ref: ref,
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

  Widget _buildExpiryTimeInfo(dynamic expiryTimeData) {
    try {
      // Parse the expiry time
      DateTime expiryTime;
      if (expiryTimeData is String) {
        expiryTime = DateTime.parse(expiryTimeData);
      } else if (expiryTimeData is Map && expiryTimeData['\$date'] != null) {
        // Handle MongoDB date format
        int timestamp = int.parse(expiryTimeData['\$date']['\$numberLong']);
        expiryTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      } else {
        return const SizedBox.shrink(); // Invalid format, don't show anything
      }
      
      // Calculate days remaining
      final now = DateTime.now();
      final difference = expiryTime.difference(now);
      final daysRemaining = difference.inDays;
      
      // Choose color based on days remaining
      Color textColor = Colors.green;
      if (daysRemaining < 30) {
        textColor = Colors.orange;
      }
      if (daysRemaining < 7) {
        textColor = Colors.red;
      }
      
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          const Text(
            'Anchor Expiry',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildDetailRow('Expires On', DateFormat('MMM d, yyyy').format(expiryTime)),
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 100,
                  child: Text(
                    'Remaining:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    '$daysRemaining days',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    } catch (e) {
      print('Error parsing expiry time: $e');
      return const SizedBox.shrink();
    }
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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location copied to clipboard')),
        );
      }
    } catch (e) {
      print('Error sharing location: $e');
      if (mounted) {
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
