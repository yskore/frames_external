import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frames_app/core/repositories/offer_repository.dart';
import 'package:frames_app/models/offer_model.dart';
import 'package:frames_app/providers/error_provider.dart';
import 'package:frames_app/providers/loading_provider.dart';

// Provider for the offer repository
final offerRepositoryProvider = Provider<OfferRepository>((ref) {
  return OfferRepository();
});

final madeOffersProvider =
    StateNotifierProvider<OfferNotifier, List<OfferModel>>((ref) {
  final offerRepository = ref.watch(offerRepositoryProvider);
  final loadingNotifier = ref.watch(loadingProvider.notifier);
  final errorNotifier = ref.watch(errorProvider.notifier);
  final messageNotifier = ref.watch(messageProvider.notifier);

  return OfferNotifier(
    offerRepository: offerRepository,
    loadingNotifier: loadingNotifier,
    errorNotifier: errorNotifier,
    messageNotifier: messageNotifier,
    isMadeOffers: true,
  );
});

final receivedOffersProvider =
    StateNotifierProvider<OfferNotifier, List<OfferModel>>((ref) {
  final offerRepository = ref.watch(offerRepositoryProvider);
  final loadingNotifier = ref.watch(loadingProvider.notifier);
  final errorNotifier = ref.watch(errorProvider.notifier);
  final messageNotifier = ref.watch(messageProvider.notifier);

  return OfferNotifier(
    offerRepository: offerRepository,
    loadingNotifier: loadingNotifier,
    errorNotifier: errorNotifier,
    isMadeOffers: false,
    messageNotifier: messageNotifier,
  );
});

// Provider for offers on a specific piece
final pieceOffersProvider =
    StateNotifierProvider.family<PieceOfferNotifier, List<OfferModel>, String>(
        (ref, pieceId) {
  final offerRepository = ref.watch(offerRepositoryProvider);
  final loadingNotifier = ref.watch(loadingProvider.notifier);
  final errorNotifier = ref.watch(errorProvider.notifier);
  final messageNotifier = ref.watch(messageProvider.notifier);

  return PieceOfferNotifier(
    offerRepository: offerRepository,
    loadingNotifier: loadingNotifier,
    messageNotifier: messageNotifier,
    errorNotifier: errorNotifier,
    pieceId: pieceId,
  );
});

class OfferNotifier extends StateNotifier<List<OfferModel>> {
  final OfferRepository offerRepository;
  final LoadingNotifier loadingNotifier;
  final ErrorNotifier errorNotifier;
  final MessageNotifier messageNotifier;
  final bool isMadeOffers;

  OfferNotifier({
    required this.offerRepository,
    required this.loadingNotifier,
    required this.errorNotifier,
    required this.messageNotifier,
    required this.isMadeOffers,
  }) : super([]) {
    // DO NOT call loadOffers() directly here - this is causing the error
    // The initialization should be done after the provider is fully constructed
    // We'll call this manually when needed (e.g., in initState)
  }

  Future<void> loadOffers() async {
    try {
      loadingNotifier.setLoading(true);
      errorNotifier.clearError();

      final response = isMadeOffers
          ? await offerRepository.getMadeOffers()
          : await offerRepository.getReceivedOffers();

      if (response.isSuccess && response.data != null) {
        if (isMadeOffers) {
          // Handling Made Offers (direct list)
          final offersData = response.data!['offers'] as List<dynamic>;
          final offers = offersData
              .map((json) => OfferModel.fromJson(json))
              .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

          state = offers;
        } else {
          // Handling Received Offers (grouped by piece)
          final pieceOffersMap =
              response.data!['offers'] as Map<String, dynamic>;
          final List<OfferModel> allOffers = [];

          pieceOffersMap.forEach((pieceId, offersForPiece) {
            final List<dynamic> offersList = offersForPiece as List<dynamic>;
            for (final offerData in offersList) {
              allOffers.add(OfferModel.fromJson(offerData));
            }
          });

          allOffers.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          state = allOffers;
        }
      } else {
        errorNotifier.setError(response.message ?? 'Failed to load offers');
        state = [];
      }
    } catch (e) {
      errorNotifier.setError('Error loading offers: $e');
      state = [];
    } finally {
      loadingNotifier.setLoading(false);
    }
  }

  Future<bool> createOffer({
    required String pieceId,
  }) async {
    try {
      loadingNotifier.setLoading(true);
      errorNotifier.clearError();

      final response = await offerRepository.createOffer(
        pieceId: pieceId,
      );

      if (response.isSuccess) {
        await loadOffers();
        messageNotifier.setSuccess('Offer submitted successfully');
        return true;
      } else {
        errorNotifier.setError(response.message ?? 'Failed to create offer');
        return false;
      }
    } catch (e) {
      errorNotifier.setError('Error creating offer: $e');
      return false;
    } finally {
      loadingNotifier.setLoading(false);
    }
  }

  Future<bool> acceptOffer(String offerId) async {
    try {
      loadingNotifier.setLoading(true);
      errorNotifier.clearError();

      final response = await offerRepository.acceptOffer(offerId);

      if (response.isSuccess) {
        await loadOffers();
        messageNotifier.setSuccess('Offer accepted successfully');
        return true;
      } else {
        errorNotifier.setError(response.message ?? 'Failed to accept offer');
        return false;
      }
    } catch (e) {
      errorNotifier.setError('Error accepting offer: $e');
      return false;
    } finally {
      loadingNotifier.setLoading(false);
    }
  }

  Future<bool> declineOffer(String offerId) async {
    try {
      loadingNotifier.setLoading(true);
      errorNotifier.clearError();

      final response = await offerRepository.declineOffer(offerId);

      if (response.isSuccess) {
        await loadOffers();
        messageNotifier.setSuccess('Offer declined successfully');

        return true;
      } else {
        errorNotifier.setError(response.message ?? 'Failed to decline offer');
        return false;
      }
    } catch (e) {
      errorNotifier.setError('Error declining offer: $e');
      return false;
    } finally {
      loadingNotifier.setLoading(false);
    }
  }

  Future<bool> cancelOffer(String offerId) async {
    try {
      loadingNotifier.setLoading(true);
      errorNotifier.clearError();

      final response = await offerRepository.cancelOffer(offerId);

      if (response.isSuccess) {
        await loadOffers();
        messageNotifier.setSuccess('Offer canceled successfully');
        return true;
      } else {
        errorNotifier.setError(response.message ?? 'Failed to cancel offer');
        return false;
      }
    } catch (e) {
      errorNotifier.setError('Error canceling offer: $e');
      return false;
    } finally {
      loadingNotifier.setLoading(false);
    }
  }

  Future<bool> submitPaymentProof(String offerId, File proofImage) async {
    try {
      loadingNotifier.setLoading(true);
      errorNotifier.clearError();

      final response =
          await offerRepository.submitPaymentProof(offerId, proofImage);

      if (response.isSuccess) {
        await loadOffers();
        messageNotifier.setSuccess('Payment proof submitted successfully');
        return true;
      } else {
        errorNotifier
            .setError(response.message ?? 'Failed to submit payment proof');
        return false;
      }
    } catch (e) {
      errorNotifier.setError('Error submitting payment proof: $e');
      return false;
    } finally {
      loadingNotifier.setLoading(false);
    }
  }

  Future<bool> confirmPayment(String offerId) async {
    try {
      loadingNotifier.setLoading(true);
      errorNotifier.clearError();

      final response = await offerRepository.confirmPayment(offerId);

      if (response.isSuccess) {
        await loadOffers();
        messageNotifier.setSuccess('Payment confirmed successfully');

        return true;
      } else {
        errorNotifier.setError(response.message ?? 'Failed to confirm payment');
        return false;
      }
    } catch (e) {
      errorNotifier.setError('Error confirming payment: $e');
      return false;
    } finally {
      loadingNotifier.setLoading(false);
    }
  }

  Future<bool> denyPayment(String offerId, String reason) async {
    try {
      loadingNotifier.setLoading(true);
      errorNotifier.clearError();

      final response = await offerRepository.denyPayment(offerId, reason);

      if (response.isSuccess) {
        await loadOffers();
        messageNotifier.setSuccess('Payment denied successfully');
        return true;
      } else {
        errorNotifier.setError(response.message ?? 'Failed to deny payment');
        return false;
      }
    } catch (e) {
      errorNotifier.setError('Error denying payment: $e');
      return false;
    } finally {
      loadingNotifier.setLoading(false);
    }
  }
}

class PieceOfferNotifier extends StateNotifier<List<OfferModel>> {
  final OfferRepository offerRepository;
  final LoadingNotifier loadingNotifier;
  final ErrorNotifier errorNotifier;
  final MessageNotifier messageNotifier;
  final String pieceId;

  PieceOfferNotifier({
    required this.offerRepository,
    required this.messageNotifier,
    required this.loadingNotifier,
    required this.errorNotifier,
    required this.pieceId,
  }) : super([]) {
    // DO NOT call loadOffers() directly here - this is causing the error
    // The initialization should be done after the provider is fully constructed
  }

  Future<void> loadOffers() async {
    try {
      loadingNotifier.setLoading(true);
      errorNotifier.clearError();

      final response = await offerRepository.getPieceOffers(pieceId);

      if (response.isSuccess && response.data != null) {
        final offersData = response.data!['offers'] as List<dynamic>;
        final offers = offersData
            .map((json) => OfferModel.fromJson(json))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        state = offers;
      } else {
        errorNotifier
            .setError(response.message ?? 'Failed to load piece offers');
        state = [];
      }
    } catch (e) {
      errorNotifier.setError('Error loading piece offers: $e');
      state = [];
    } finally {
      loadingNotifier.setLoading(false);
    }
  }
}
