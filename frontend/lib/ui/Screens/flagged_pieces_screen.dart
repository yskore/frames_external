import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frames_app/Providers/flagged_pieces_provider.dart';
import 'package:frames_app/models/flagged_piece_model.dart';
import 'package:image_picker/image_picker.dart';

class FlaggedPiecesScreen extends ConsumerStatefulWidget {
  const FlaggedPiecesScreen({super.key});

  @override
  ConsumerState<FlaggedPiecesScreen> createState() =>
      _FlaggedPiecesScreenState();
}

class _FlaggedPiecesScreenState extends ConsumerState<FlaggedPiecesScreen> {
  final ImagePicker _picker = ImagePicker();

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
                  flaggedPiece.hasUnacknowledgedResolution
                      ? Icons.info
                      : flaggedPiece.isActiveFlagged
                          ? Icons.warning
                          : Icons.flag,
                  color: flaggedPiece.hasUnacknowledgedResolution
                      ? Colors.blue[700]
                      : flaggedPiece.isActiveFlagged
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

            // Show dispute resolution if available and unacknowledged
            if (flaggedPiece.hasUnacknowledgedResolution)
              _buildDisputeResolutionCard(flaggedPiece)
            else
              _buildFlagDetailsCard(flaggedPiece),

            const SizedBox(height: 16),

            // Action buttons
            if (flaggedPiece.hasUnacknowledgedResolution)
              _buildAcknowledgeButton(flaggedPiece)
            else if (flaggedPiece.isActiveFlagged && !flaggedPiece.isDeleted)
              _buildActionButtons(flaggedPiece)
            else
              _buildInfoCard(flaggedPiece),
          ],
        ),
      ),
    );
  }

  Widget _buildDisputeResolutionCard(FlaggedPiece flaggedPiece) {
    final resolution = flaggedPiece.disputeResolution!;
    final isAccepted = resolution.status == 'accepted';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isAccepted ? Colors.green[50] : Colors.red[50],
        border: Border.all(
          color: isAccepted ? Colors.green[200]! : Colors.red[200]!,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isAccepted ? Icons.check_circle : Icons.cancel,
                color: isAccepted ? Colors.green[700] : Colors.red[700],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                resolution.statusDisplay,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isAccepted ? Colors.green[700] : Colors.red[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isAccepted
                ? 'Good news! Your dispute was accepted by the moderation team. Your piece has been restored.'
                : 'Your dispute was rejected by the moderation team. The original flag decision stands.',
            style: TextStyle(
              fontSize: 14,
              color: isAccepted ? Colors.green[800] : Colors.red[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Resolved: ${_formatDate(resolution.resolvedAt)}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlagDetailsCard(FlaggedPiece flaggedPiece) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getStatusColor(flaggedPiece.flagStatus)[50],
        border:
            Border.all(color: _getStatusColor(flaggedPiece.flagStatus)[200]!),
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
    );
  }

  Widget _buildAcknowledgeButton(FlaggedPiece flaggedPiece) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _acknowledgeDisputeResolution(flaggedPiece),
        icon: const Icon(Icons.check, size: 18),
        label: const Text('Acknowledge'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[50],
          foregroundColor: Colors.blue[700],
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildActionButtons(FlaggedPiece flaggedPiece) {
    return Row(
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

  Widget _buildInfoCard(FlaggedPiece flaggedPiece) {
    return Container(
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
    String? selectedFilePath;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
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
                      'Upload Evidence File (optional):',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              FilePickerResult? result =
                                  await FilePicker.platform.pickFiles(
                                type: FileType.custom,
                                allowedExtensions: [
                                  'jpg',
                                  'jpeg',
                                  'png',
                                  'pdf'
                                ],
                                allowMultiple: false,
                              );

                              if (result != null) {
                                setState(() {
                                  selectedFilePath = result.files.single.path;
                                });
                              }
                            },
                            icon: const Icon(Icons.attach_file),
                            label: Text(selectedFilePath != null
                                ? 'File Selected'
                                : 'Select File'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: selectedFilePath != null
                                  ? Colors.green[50]
                                  : Colors.grey[50],
                              foregroundColor: selectedFilePath != null
                                  ? Colors.green[700]
                                  : Colors.grey[700],
                            ),
                          ),
                        ),
                        if (selectedFilePath != null) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                selectedFilePath = null;
                              });
                            },
                            icon: const Icon(Icons.clear),
                            color: Colors.red,
                          ),
                        ],
                      ],
                    ),
                    if (selectedFilePath != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Selected: ${selectedFilePath!.split('/').last}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
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
                        'Your dispute will be reviewed by our moderation team. You can provide either a URL or upload a file as evidence.',
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
                      filePath: selectedFilePath,
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
      FlaggedPiece flaggedPiece, String evidence, String comments,
      {String? filePath}) async {
    final success = await ref.read(flaggedPiecesProvider.notifier).disputeFlag(
        flaggedPiece.pieceId, evidence, comments,
        filePath: filePath);

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

  Future<void> _acknowledgeDisputeResolution(FlaggedPiece flaggedPiece) async {
    final success = await ref
        .read(flaggedPiecesProvider.notifier)
        .acknowledgeDisputeResolution(flaggedPiece.pieceId);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dispute resolution acknowledged'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}
