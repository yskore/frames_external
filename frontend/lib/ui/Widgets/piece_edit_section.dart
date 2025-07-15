// piece_edit_section.dart
import 'package:currency_picker/currency_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frames_app/core/mixins/message_mixin.dart';
import 'package:frames_app/core/repositories/piece_repository.dart';
import 'package:frames_app/models/piece_model.dart';
import 'package:frames_app/providers/user_provider.dart';

class PieceEditManager with MessageMixin {
  final WidgetRef ref;
  final Piece piece;
  final TextEditingController nameController;
  final TextEditingController descriptionController;
  final TextEditingController priceController;
  final TextEditingController paymentDetailsController;
  final TextEditingController currencyController;
  final String Function() getCurrentOwnership;
  final Function(bool) setLoading;
  final Function(Piece) updatePiece;
  bool currentForSaleState;
  bool currentHiddenState;
  int currentShowRadius;

  PieceEditManager({
    required this.ref,
    required this.piece,
    required this.nameController,
    required this.descriptionController,
    required this.priceController,
    required this.paymentDetailsController,
    required this.currencyController,
    required this.getCurrentOwnership,
    required this.setLoading,
    required this.updatePiece,
  })  : currentForSaleState = piece.pieceForSale,
        currentHiddenState = piece.isHidden,
        currentShowRadius = piece.showRadius;

  // In piece_edit_section.dart
// In piece_edit_section.dart

  void updateHiddenState(bool newState) {
    currentHiddenState = newState;
    if (!newState) currentShowRadius = 0; // Reset radius when unhiding
  }

  void updateShowRadius(int newRadius) {
    currentShowRadius = newRadius;
  }

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
          title: const Text('Delete Piece'),
          content: const Text(
              'Are you sure you want to delete this piece? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                onDelete();
                Navigator.of(context).pop(); // Close dialog
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void updateForSaleState(bool newState) {
    currentForSaleState = newState;
  }

  Future<bool> savePieceChanges() async {
    setLoading(true);

    try {
      final pieceRepository = ref.read(pieceRepositoryProvider);
      String? paymentDetails;
      if (currentForSaleState) {
        // Use the tracked state
        paymentDetails = paymentDetailsController.text;
      }

      final response = await pieceRepository.updatePieceInfo(
        pieceOwner: piece.pieceOwner,
        oldPieceTitle: piece.pieceTitle,
        newPieceTitle: nameController.text,
        pieceDescription: descriptionController.text,
        pieceForSale: currentForSaleState, // Use the tracked state
        piecePrice: double.tryParse(priceController.text) ?? 0.0,
        ownership: getCurrentOwnership(),
        paymentDetails: paymentDetails,
        currency: currencyController.text,
        isHidden: currentHiddenState, // ADD
        showRadius: currentShowRadius,
      );

      if (response.isSuccess) {
        final updatedPiece = piece.copyWith(
          pieceTitle: nameController.text,
          pieceDescription: descriptionController.text,
          piecePrice: double.tryParse(priceController.text) ?? piece.piecePrice,
          paymentDetails: currentForSaleState
              ? paymentDetailsController.text
              : piece.paymentDetails,
          currency: currencyController.text,
          pieceForSale: currentForSaleState, // Include the updated state
          isHidden: currentHiddenState, // ADD
          showRadius: currentShowRadius,
          ownership: getCurrentOwnership(),
        );

        updatePiece(updatedPiece);

        // Explicitly refresh user data first - no showLoading to avoid UI flicker
        await ref
            .read(userNotifierProvider)
            .refreshUserData(showLoading: false);

        return true;
      } else {
        throw Exception(response.message ?? 'Failed to update piece');
      }
    } catch (e) {
      showError('Failed to update piece: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }
}
