// piece_edit_section.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frames_app/core/repositories/piece_repository.dart';
import 'package:frames_app/models/piece_model.dart';
import 'package:frames_app/providers/error_provider.dart';
import 'package:frames_app/providers/user_provider.dart';
import 'package:currency_picker/currency_picker.dart';

class PieceEditManager {
  final WidgetRef ref;
  final Piece piece;
  final TextEditingController nameController;
  final TextEditingController descriptionController;
  final TextEditingController priceController;
  final TextEditingController paymentDetailsController;
  final TextEditingController currencyController;
  final String ownership;
  final Function(bool) setLoading;
  final Function(Piece) updatePiece;

  PieceEditManager({
    required this.ref,
    required this.piece,
    required this.nameController,
    required this.descriptionController,
    required this.priceController,
    required this.paymentDetailsController,
    required this.currencyController,
    required this.ownership,
    required this.setLoading,
    required this.updatePiece,
  });

 // In piece_edit_section.dart
// In piece_edit_section.dart
void openCurrencyPicker(BuildContext context) {
  showCurrencyPicker(
    context: context,
    showFlag: true,
    showCurrencyName: true,
    showCurrencyCode: true,
    onSelect: (Currency currency) {
      currencyController.text = currency.code;
    },
  );
}

  void showDeleteConfirmation(BuildContext context, Function() onDelete) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Piece'),
          content: Text('Are you sure you want to delete this piece? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                onDelete();
                Navigator.of(context).pop(); // Close dialog
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<bool> savePieceChanges() async {
    setLoading(true);

    try {
      final pieceRepository = ref.read(pieceRepositoryProvider);
      String? paymentDetails;
      if (piece.pieceForSale) {
        paymentDetails = paymentDetailsController.text;
      }
      
      final response = await pieceRepository.updatePieceInfo(
        pieceOwner: piece.pieceOwner,
        oldPieceTitle: piece.pieceTitle,
        newPieceTitle: nameController.text,
        pieceDescription: descriptionController.text,
        pieceForSale: piece.pieceForSale,
        piecePrice: double.tryParse(priceController.text) ?? 0.0,
        ownership: ownership,
        paymentDetails: paymentDetails,
        currency: currencyController.text,
      );

      if (response.isSuccess) {
        final updatedPiece = piece.copyWith(
          pieceTitle: nameController.text,
          pieceDescription: descriptionController.text,
          piecePrice: double.tryParse(priceController.text) ?? piece.piecePrice,
          paymentDetails: piece.pieceForSale ? paymentDetailsController.text : piece.paymentDetails,
          currency: currencyController.text,
        );
        
        updatePiece(updatedPiece);

        // Explicitly refresh user data first - no showLoading to avoid UI flicker
        await ref.read(userNotifierProvider).refreshUserData(showLoading: false);
        
        return true;
      } else {
        throw Exception(response.message ?? 'Failed to update piece');
      }
    } catch (e) {
      ref.read(errorProvider.notifier).setError('Failed to update piece: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }
}