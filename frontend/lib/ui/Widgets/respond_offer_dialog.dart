import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frames_app/models/offer_model.dart';
import 'package:frames_app/providers/offer_provider.dart';

class RespondOfferDialog extends ConsumerStatefulWidget {
  final OfferModel offer;
  final bool accept;

  const RespondOfferDialog({
    super.key,
    required this.offer,
    required this.accept,
  });

  static Future<bool?> show(
      BuildContext context, OfferModel offer, bool accept) {
    return showDialog<bool>(
      context: context,
      builder: (context) => RespondOfferDialog(offer: offer, accept: accept),
    );
  }

  @override
  ConsumerState<RespondOfferDialog> createState() => _RespondOfferDialogState();
}

class _RespondOfferDialogState extends ConsumerState<RespondOfferDialog> {
  bool _isLoading = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final title = widget.accept ? 'Accept Offer' : 'Decline Offer';
    final message = widget.accept
        ? 'Are you sure you want to accept this offer for ${widget.offer.pieceTitle ?? 'this piece'}? '
            'Once accepted, other pending offers will be cancelled and the buyer will have a limited time to submit payment.'
        : 'Are you sure you want to decline this offer for ${widget.offer.pieceTitle ?? 'this piece'}? '
            'This action cannot be undone.';

    final buttonText = widget.accept ? 'Accept' : 'Decline';
    final buttonColor = widget.accept ? Colors.green : Colors.red;

    return AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message),
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleResponse,
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonColor,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(buttonText),
        ),
      ],
    );
  }

  Future<void> _handleResponse() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = widget.accept
          ? await ref
              .read(receivedOffersProvider.notifier)
              .acceptOffer(widget.offer.id)
          : await ref
              .read(receivedOffersProvider.notifier)
              .declineOffer(widget.offer.id);

      if (result && mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
