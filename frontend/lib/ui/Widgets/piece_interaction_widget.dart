import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frames_app/Providers/like_provider.dart';
import 'package:frames_app/core/services/map.dart';

class PieceInteractionWidget extends ConsumerStatefulWidget {
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
  ConsumerState<PieceInteractionWidget> createState() => _PieceInteractionWidgetState();
}

class _PieceInteractionWidgetState extends ConsumerState<PieceInteractionWidget> {
  String? pieceId;
  Map<String, dynamic>? pieceJson;
  bool _isAnimatingLike = false;
  
  @override
  void initState() {
    super.initState();
    _parsePieceData();
    _checkLikeStatus();
  }
  
  void _parsePieceData() {
    try {
      pieceJson = jsonDecode(widget.pieceData);
      pieceId = pieceJson?['pieceid'] ?? pieceJson?['PieceID'];
      
      if (pieceId != null) {
        // Initialize like count (could be 0 if not set)
        final likeCount = pieceJson?['Piece_likes'] ?? 0;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(pieceLikeCountProvider(pieceId!).notifier).state = likeCount;
        });
      }
    } catch (e) {
      print('Error parsing piece data: $e');
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

  Future<void> _handleLikeToggle() async {
    if (pieceId == null) return;
    
    setState(() {
      _isAnimatingLike = true;
    });
    
    try {
      await ref.read(likeNotifierProvider).toggleLike(
        pieceId!,
        showLoading: false,
      );
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
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: const [
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
                    // Title
                    Text(
                      pieceJson?['frameName'] ?? 'Unknown Piece',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Image if available
                    if (pieceJson?['imageUrl'] != null)
                      Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(
                            image: NetworkImage(pieceJson!['imageUrl']),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    
                    const SizedBox(height: 16),
                    
                    // Action buttons row: Like and Get Directions
                    Row(
                      children: [
                        // Like button with animation
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              transitionBuilder: (child, animation) {
                                return ScaleTransition(
                                  scale: animation,
                                  child: child,
                                );
                              },
                              child: _isAnimatingLike
                                ? const SizedBox(
                                    key: ValueKey('loading'),
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                                    ),
                                  )
                                : Icon(
                                    isLiked ? Icons.favorite : Icons.favorite_border,
                                    key: ValueKey(isLiked),
                                    color: Colors.red,
                                  ),
                            ),
                            label: Text(isLiked ? 'Liked ($likeCount)' : 'Like ($likeCount)'),
                            onPressed: _isAnimatingLike ? null : _handleLikeToggle,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              // Highlight button if liked
                              backgroundColor: isLiked ? Colors.red.withOpacity(0.1) : null,
                            ),
                          ),
                        ),
                        
                        const SizedBox(width: 8),
                        
                        // Get Directions button
                        if (pieceJson?['latitude'] != null && pieceJson?['longitude'] != null)
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.directions),
                              label: const Text('Directions'),
                              onPressed: () {
                                try {
                                  // Use MapService to navigate
                                  MapService.openGoogleMapsNavigation(
                                    pieceJson!['latitude'],
                                    pieceJson!['longitude'],
                                    ref: ref,
                                  );
                                } catch (e) {
                                  print('Error opening maps: $e');
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Could not open maps')),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
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
                          if (pieceId != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                'Piece ID: $pieceId',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ),

                          // Anchor information if available
                          if (pieceJson?['anchorId'] != null) 
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                'Anchor ID: ${pieceJson!['anchorId']}',
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
              padding: const EdgeInsets.all(16),
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: widget.onClose,
                      child: const Text('Close'),
                    ),
                    if (widget.onViewDetails != null)
                      ElevatedButton(
                        onPressed: widget.onViewDetails,
                        child: const Text('More Details'),
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
            const Text('Error loading piece information'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: widget.onClose,
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}
