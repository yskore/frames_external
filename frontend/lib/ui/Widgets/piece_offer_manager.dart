// piece_offer_manager.dart
import 'package:flutter/material.dart';
import 'package:frames_app/models/piece_model.dart';

class PieceOfferManager {
  final Piece piece;
  final TextEditingController paymentDetailsController;

  PieceOfferManager({
    required this.piece,
    required this.paymentDetailsController,
  });

  void showMakeOfferDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Make an Offer'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Would you like to make an offer for ${piece.pieceTitle}?'),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('Price: ',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    '${piece.currency ?? 'USD'} ${piece.piecePrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.green,
                    )),
                ],
              ),
              const SizedBox(height: 16),

              // Display payment details as read-only rich text if available
               if (piece.paymentDetails != null &&
                  piece.paymentDetails!.isNotEmpty) ...[
                const Text('Payment Details:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: TextField(
                    controller: paymentDetailsController,
                    maxLines: null,
                    expands: true,
                    readOnly: true,
                    textAlignVertical: TextAlignVertical.top,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.all(8),
                      hintText: '...',
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              const Text(
                'By clicking "Make Offer", you agree to pay the listed price',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // TODO: Implement make offer functionality
                Navigator.of(context).pop();
              },
              child: Text('Make Offer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
              ),
            ),
          ],
        );
      },
    );
  }
}