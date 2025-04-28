import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frames_app/models/offer_model.dart';
import 'package:frames_app/providers/offer_provider.dart';

class RespondPaymentDialog extends ConsumerStatefulWidget {
  final OfferModel offer;
  final bool confirm;

  const RespondPaymentDialog({
    super.key,
    required this.offer,
    required this.confirm,
  });

  static Future<bool?> show(
      BuildContext context, OfferModel offer, bool confirm) {
    return showDialog<bool>(
      context: context,
      builder: (context) =>
          RespondPaymentDialog(offer: offer, confirm: confirm),
    );
  }

  @override
  ConsumerState<RespondPaymentDialog> createState() =>
      _RespondPaymentDialogState();
}

class _RespondPaymentDialogState extends ConsumerState<RespondPaymentDialog> {
  final TextEditingController _reasonController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.confirm ? 'Confirm Payment' : 'Reject Payment';

    return AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.confirm
              ? 'Are you sure you want to confirm this payment? '
                  'This will complete the transaction and transfer ownership of the piece.'
              : 'Are you sure you want to reject this payment? '
                  'This will open a dispute process.'),
          const SizedBox(height: 16),
          if (!widget.confirm) ...[
            TextField(
              controller: _reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for rejection (required)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 8),
            const Text(
              'Please provide a detailed reason for rejecting the payment. This will help resolve any disputes.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
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
            backgroundColor: widget.confirm ? Colors.green : Colors.red,
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
              : Text(widget.confirm ? 'Confirm Payment' : 'Reject Payment'),
        ),
      ],
    );
  }

  Future<void> _handleResponse() async {
    // For payment rejection, require a reason
    if (!widget.confirm && _reasonController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please provide a reason for rejection';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = widget.confirm
          ? await ref
              .read(receivedOffersProvider.notifier)
              .confirmPayment(widget.offer.id)
          : await ref
              .read(receivedOffersProvider.notifier)
              .denyPayment(widget.offer.id, _reasonController.text.trim());

      if (result && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Payment ${widget.confirm ? 'confirmed' : 'rejected'} successfully'),
            backgroundColor: widget.confirm ? Colors.green : Colors.orange,
          ),
        );
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
