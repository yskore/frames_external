import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frames_app/Providers/piece_provider.dart';
import 'package:frames_app/models/piece_model.dart';

class PieceFlagManager {
  final WidgetRef ref;
  final Piece piece;

  PieceFlagManager({
    required this.ref,
    required this.piece,
  });

  void showFlagDialog(BuildContext context) {
    String selectedReason = '';

    final List<Map<String, String>> flagReasons = [
      {
        'value': 'Inappropriate',
        'title': 'Inappropriate',
        'description': 'When a piece uses mature, abusive, gruesome imagery'
      },
      {
        'value': 'Piracy',
        'title': 'Piracy',
        'description':
            'When a piece uses imagery which is a copy of an existing physical/digital work not owned by the owner'
      },
    ];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.flag, color: Colors.red[400]),
                  const SizedBox(width: 8),
                  const Text('Flag Piece'),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Why are you flagging "${piece.pieceTitle}"?',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 16),
                    ...flagReasons.map((reason) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: RadioListTile<String>(
                            title: Text(
                              reason['title']!,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            subtitle: Text(
                              reason['description']!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            value: reason['value']!,
                            groupValue: selectedReason,
                            onChanged: (value) {
                              setState(() {
                                selectedReason = value!;
                              });
                            },
                            dense: false,
                            contentPadding: EdgeInsets.zero,
                          ),
                        )),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        border: Border.all(color: Colors.orange[200]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: Colors.orange[700], size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Flagged content will be reviewed by our moderation team.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: selectedReason.isEmpty
                      ? null
                      : () async {
                          await _submitFlag(context, selectedReason);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Submit Flag'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _submitFlag(BuildContext context, String flagType) async {
    try {
      final pieceNotifier = ref.read(pieceProvider.notifier);

      final success = await pieceNotifier.flagPiece(
        pieceId: piece.pieceid,
        flagType: flagType,
      );

      if (context.mounted) {
        Navigator.of(context).pop(); // Close flag dialog

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Thank you for your report. We will review it shortly.'),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
        // Error handling is managed by the piece provider through errorProvider
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit flag: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
