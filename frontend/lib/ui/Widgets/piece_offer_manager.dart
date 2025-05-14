
import 'dart:async';
import 'dart:convert';

import 'package:currency_picker/currency_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:flutter_unity_widget/flutter_unity_widget.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Add import for offer_provider
import 'package:frames_app/Providers/offer_provider.dart';
import 'package:frames_app/core/repositories/anchor_repository.dart';
import 'package:frames_app/core/repositories/piece_repository.dart';
import 'package:frames_app/core/services/map.dart';
import 'package:frames_app/core/services/unity_scene_service.dart';
import 'package:frames_app/models/anchor_model.dart';
import 'package:frames_app/models/piece_model.dart';
import 'package:frames_app/providers/error_provider.dart';
import 'package:frames_app/providers/user_provider.dart';
import 'package:frames_app/ui/Screens/user_profile_screen.dart';
import 'package:frames_app/ui/Widgets/AR_Piece_placement.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class PieceOfferManager {
  final WidgetRef ref;
  final Piece piece;
  final TextEditingController paymentDetailsController;

  PieceOfferManager({
    required this.ref,
    required this.piece,
    required this.paymentDetailsController,
  });

 Future<void> _handleClosing(context) async {

    try {
      // Use the SceneManager to safely dispose the controller
      final sceneManager = ref.read(unitySceneManagerProvider);
      if (sceneManager.isUnityInitialized) {
        await sceneManager.safeDisposeController();
      }

      // Short delay to ensure everything is cleaned up
      await Future.delayed(const Duration(milliseconds: 100));
        Navigator.of(context).pop();
      
    } catch (e) {
      print('Error during closing: $e');
      
        Navigator.of(context).pop();
      
    }
  }


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
                  // Show loading indicator
                final offerNotifier = ref.read(madeOffersProvider.notifier);
                offerNotifier.createOffer(
                  pieceId: piece.pieceid,
                );
                _handleClosing(context) ; 
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