import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:frames_app/core/network/api_response.dart';
import 'package:frames_app/core/network/api_service.dart';

class OfferRepository {
  final ApiService _apiService = ApiService();

  // Get user's sent offers
  Future<ApiResponse> getMadeOffers() async {
    try {
      final response = await _apiService.get('my-made-offers');
      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting made offers: $e');
      }
      return ApiResponse.error('Failed to fetch sent offers: $e');
    }
  }

  // Get user's received offers
  Future<ApiResponse> getReceivedOffers() async {
    try {
      final response = await _apiService.get('my-received-offers');
      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting received offers: $e');
      }
      return ApiResponse.error('Failed to fetch received offers: $e');
    }
  }

  // Get offers for a specific piece
  Future<ApiResponse> getPieceOffers(String pieceId) async {
    try {
      final response = await _apiService.get('piece-offers/$pieceId');
      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting piece offers: $e');
      }
      return ApiResponse.error('Failed to fetch piece offers: $e');
    }
  }

  // Create an offer for a piece
  Future<ApiResponse> createOffer({
    required String pieceId,
  }) async {
    try {
      final response = await _apiService.post(
        'create-offer',
        data: {
          'piece_id': pieceId,
        },
      );

      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating offer: $e');
      }
      return ApiResponse.error('Failed to create offer: $e');
    }
  }

  // Accept an offer
  Future<ApiResponse> acceptOffer(String offerId) async {
    try {
      final response = await _apiService.post('accept-offer/$offerId');
      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Error accepting offer: $e');
      }
      return ApiResponse.error('Failed to accept offer: $e');
    }
  }

  // Decline an offer
  Future<ApiResponse> declineOffer(String offerId) async {
    try {
      final response = await _apiService.post('decline-offer/$offerId');
      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Error declining offer: $e');
      }
      return ApiResponse.error('Failed to decline offer: $e');
    }
  }

  // Cancel an offer
  Future<ApiResponse> cancelOffer(String offerId) async {
    try {
      final response = await _apiService.post('cancel-offer/$offerId');
      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Error canceling offer: $e');
      }
      return ApiResponse.error('Failed to cancel offer: $e');
    }
  }

  // Submit payment proof
  Future<ApiResponse> submitPaymentProof(
      String offerId, File proofImage) async {
    try {
      // Create form data with the image
      final formData = {
        'image': proofImage,
      };

      final response = await _apiService.postMultipart(
          'submit-payment-proof/$offerId',
          data: {},
          files: {'image': proofImage});

      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Error submitting payment proof: $e');
      }
      return ApiResponse.error('Failed to submit payment proof: $e');
    }
  }

  // Get payment proof
  Future<ApiResponse> getPaymentProof(String offerId) async {
    try {
      final response = await _apiService.get('payment-proof/$offerId');
      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting payment proof: $e');
      }
      return ApiResponse.error('Failed to get payment proof: $e');
    }
  }

  // Confirm payment
  Future<ApiResponse> confirmPayment(String offerId) async {
    try {
      final response = await _apiService.post('confirm-payment/$offerId');
      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Error confirming payment: $e');
      }
      return ApiResponse.error('Failed to confirm payment: $e');
    }
  }

  // Deny payment
  Future<ApiResponse> denyPayment(String offerId, String reason) async {
    try {
      final response = await _apiService.post(
        'deny-payment/$offerId',
        data: {
          'reason': reason,
        },
      );

      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Error denying payment: $e');
      }
      return ApiResponse.error('Failed to deny payment: $e');
    }
  }
}
