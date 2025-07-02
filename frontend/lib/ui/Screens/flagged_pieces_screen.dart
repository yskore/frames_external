import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frames_app/Providers/flagged_pieces_provider.dart';
import 'package:frames_app/models/flagged_piece_model.dart';

class FlaggedPiecesScreen extends ConsumerStatefulWidget {
  const FlaggedPiecesScreen({super.key});

  @override
  ConsumerState<FlaggedPiecesScreen> createState() =>
      _FlaggedPiecesScreenState();
}

class _FlaggedPiecesScreenState extends ConsumerState<FlaggedPiecesScreen> {
  @override
  void initState() {
    super.initState();
    // Load flagged pieces when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(flaggedPiecesProvider.notifier).loadMyFlaggedPieces();
    });
  }

  @override
  Widget build(BuildContext context) {
    final flaggedPieces = ref.watch(flaggedPiecesProvider);
    final isLoading = ref.watch(flaggedPiecesLoadingProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flagged Pieces'),
        backgroundColor: Colors.orange[100],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : flaggedPieces.isEmpty
              ? _buildEmptyState()
              : _buildFlaggedPiecesList(flaggedPieces),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.flag_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Flagged Pieces',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You don\'t have any pieces that need your attention.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFlaggedPiecesList(List<FlaggedPiece> flaggedPieces) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: flaggedPieces.length,
      itemBuilder: (context, index) {
        final flaggedPiece = flaggedPieces[index];
        return _buildFlaggedPieceCard(flaggedPiece);
      },
    );
  }

  Widget _buildFlaggedPieceCard(FlaggedPiece flaggedPiece) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with piece title and status badge
            Row(
              children: [
                Icon(
                  flaggedPiece.isActiveFlagged ? Icons.warning : Icons.flag,
                  color: flaggedPiece.isActiveFlagged
                      ? Colors.red[700]
                      : Colors.orange[700],
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    flaggedPiece.pieceTitle,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildStatusBadge(flaggedPiece),
              ],
            ),

            const SizedBox(height: 12),

            // Flag details
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getStatusColor(flaggedPiece.flagStatus)[50],
                border: Border.all(
                    color: _getStatusColor(flaggedPiece.flagStatus)[200]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (flaggedPiece.flagType != null) ...[
                    Text(
                      'Flagged as: ${flaggedPiece.flagTypeDisplay}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _getStatusColor(flaggedPiece.flagStatus)[800],
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    'Status: ${flaggedPiece.flagStatusDisplay}',
                    style: TextStyle(
                      fontSize: 12,
                      color: _getStatusColor(flaggedPiece.flagStatus)[700],
                    ),
                  ),
                  if (flaggedPiece.flagExpiration != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Expires: ${_formatDate(flaggedPiece.flagExpiration!)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: _getStatusColor(flaggedPiece.flagStatus)[700],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Action buttons - only show for active flags
            if (flaggedPiece.isActiveFlagged && !flaggedPiece.isDeleted)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showAcceptDeleteDialog(flaggedPiece),
                      icon: const Icon(Icons.delete_forever, size: 18),
                      label: const Text('Accept & Delete'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[50],
                        foregroundColor: Colors.red[700],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showDisputeDialog(flaggedPiece),
                      icon: const Icon(Icons.gavel, size: 18),
                      label: const Text('Dispute'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[50],
                        foregroundColor: Colors.blue[700],
                      ),
                    ),
                  ),
                ],
              ),

            // Show info for resolved/disputed flags
            if (!flaggedPiece.isActiveFlagged)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _getStatusMessage(flaggedPiece.flagStatus),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
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
  }

  Widget _buildStatusBadge(FlaggedPiece flaggedPiece) {
    final color = _getStatusColor(flaggedPiece.flagStatus);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        flaggedPiece.flagStatusDisplay,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color[700],
        ),
      ),
    );
  }

  MaterialColor _getStatusColor(String status) {
    switch (status) {
      case 'pending_action':
        return Colors.red;
      case 'disputed':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      case 'deleted':
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }

  String _getStatusMessage(String status) {
    switch (status) {
      case 'disputed':
        return 'Your dispute is being reviewed by the moderation team.';
      case 'resolved':
        return 'This flag has been resolved in your favor.';
      case 'deleted':
        return 'This piece has been deleted.';
      default:
        return 'No action required.';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showAcceptDeleteDialog(FlaggedPiece flaggedPiece) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.red),
              SizedBox(width: 8),
              Text('Confirm Deletion'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  'Are you sure you want to delete "${flaggedPiece.pieceTitle}"?'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  border: Border.all(color: Colors.red[200]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'This action cannot be undone. The piece will be permanently deleted.',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _acceptAndDelete(flaggedPiece);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _showDisputeDialog(FlaggedPiece flaggedPiece) {
    final evidenceController = TextEditingController();
    final commentsController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.gavel, color: Colors.blue),
              SizedBox(width: 8),
              Text('Dispute Flag'),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Disputing flag for "${flaggedPiece.pieceTitle}"'),
                const SizedBox(height: 16),
                const Text(
                  'Evidence URL (optional):',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: evidenceController,
                  decoration: const InputDecoration(
                    hintText: 'https://example.com/evidence.jpg',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Comments:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: commentsController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Explain why this flag is incorrect...',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    border: Border.all(color: Colors.blue[200]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Your dispute will be reviewed by our moderation team.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _submitDispute(
                  flaggedPiece,
                  evidenceController.text,
                  commentsController.text,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Submit Dispute'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _acceptAndDelete(FlaggedPiece flaggedPiece) async {
    final success = await ref
        .read(flaggedPiecesProvider.notifier)
        .acceptFlag(flaggedPiece.pieceId);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Piece deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
      // Refresh the list
      ref.read(flaggedPiecesProvider.notifier).loadMyFlaggedPieces();
    }
  }

  Future<void> _submitDispute(
      FlaggedPiece flaggedPiece, String evidence, String comments) async {
    final success = await ref
        .read(flaggedPiecesProvider.notifier)
        .disputeFlag(flaggedPiece.pieceId, evidence, comments);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dispute submitted successfully'),
          backgroundColor: Colors.green,
        ),
      );
      // Refresh the list
      ref.read(flaggedPiecesProvider.notifier).loadMyFlaggedPieces();
    }
  }
}
