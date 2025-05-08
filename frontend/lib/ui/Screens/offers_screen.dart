import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frames_app/core/network/api_response.dart';
import 'package:frames_app/models/offer_model.dart';
import 'package:frames_app/providers/offer_provider.dart';
import 'package:frames_app/ui/Widgets/respond_offer_dialog.dart';
import 'package:frames_app/ui/Widgets/respond_payment_dialog.dart';
import 'package:frames_app/ui/Widgets/submit_payment_dialog.dart';
import 'package:intl/intl.dart';

class OffersScreen extends ConsumerStatefulWidget {
  const OffersScreen({super.key});

  @override
  ConsumerState<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends ConsumerState<OffersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Load offers when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(madeOffersProvider.notifier).loadOffers();
      ref.read(receivedOffersProvider.notifier).loadOffers();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Offers'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Received'),
            Tab(text: 'Sent'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          ReceivedOffersTab(),
          SentOffersTab(),
        ],
      ),
    );
  }
}

class ReceivedOffersTab extends ConsumerWidget {
  const ReceivedOffersTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offers = ref.watch(receivedOffersProvider);

    if (offers.isEmpty) {
      return const Center(
        child: Text(
          'No offers received yet',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(receivedOffersProvider.notifier).loadOffers();
      },
      child: ListView.builder(
        itemCount: offers.length,
        itemBuilder: (context, index) {
          final offer = offers[index];
          return OfferCard(
            offer: offer,
            isReceived: true,
          );
        },
      ),
    );
  }
}

class SentOffersTab extends ConsumerWidget {
  const SentOffersTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offers = ref.watch(madeOffersProvider);

    if (offers.isEmpty) {
      return const Center(
        child: Text(
          'No offers sent yet',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(madeOffersProvider.notifier).loadOffers();
      },
      child: ListView.builder(
        itemCount: offers.length,
        itemBuilder: (context, index) {
          final offer = offers[index];
          return OfferCard(
            offer: offer,
            isReceived: false,
          );
        },
      ),
    );
  }
}

class OfferCard extends ConsumerWidget {
  final OfferModel offer;
  final bool isReceived;

  const OfferCard({
    super.key,
    required this.offer,
    required this.isReceived,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formatter = NumberFormat.currency(symbol: "${offer.currency} ");

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 2,
      child: InkWell(
        onTap: () => _showOfferDetailsDialog(context, ref),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      offer.pieceTitle ?? 'Untitled',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildStatusChip(offer.status),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isReceived ? 'From: ${offer.buyer}' : 'To: ${offer.seller}',
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    formatter.format(offer.amount),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Created: ${DateFormat('MMM d, y').format(offer.createdAt)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              if (offer.paymentDeadline != null &&
                  _shouldShowExpiryDate(offer.status))
                Text(
                  'Expires: ${DateFormat('MMM d, y · h:mm a').format(offer.paymentDeadline!)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: _isExpiringSoon(offer.paymentDeadline!)
                        ? Colors.red
                        : Colors.grey[600],
                    fontWeight: _isExpiringSoon(offer.paymentDeadline!)
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              const SizedBox(height: 12),
              if (offer.message != null && offer.message!.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(4.0),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Text(offer.message!),
                ),
              if (_shouldShowActions(offer.status, isReceived))
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children:
                        _buildActionButtons(context, ref, offer, isReceived),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(OfferStatus status) {
    Color chipColor;
    IconData icon;

    switch (status) {
      case OfferStatus.pending:
        chipColor = Colors.blue;
        icon = Icons.hourglass_empty;
        break;
      case OfferStatus.accepted:
        chipColor = Colors.green;
        icon = Icons.check_circle;
        break;
      case OfferStatus.rejected:
        chipColor = Colors.red;
        icon = Icons.cancel;
        break;
      case OfferStatus.cancelled:
        chipColor = Colors.grey;
        icon = Icons.block;
        break;
      case OfferStatus.paymentSubmitted:
        chipColor = Colors.purple;
        icon = Icons.receipt_long;
        break;
      case OfferStatus.completed:
        chipColor = Colors.teal;
        icon = Icons.done_all;
        break;
      case OfferStatus.disputed:
        chipColor = Colors.deepOrange;
        icon = Icons.warning_amber;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: chipColor.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: chipColor,
          ),
          const SizedBox(width: 4),
          Text(
            _formatStatus(status),
            style: TextStyle(
              fontSize: 12,
              color: chipColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatStatus(OfferStatus status) {
    switch (status) {
      case OfferStatus.pending:
        return 'Pending';
      case OfferStatus.accepted:
        return 'Accepted';
      case OfferStatus.rejected:
        return 'Rejected';
      case OfferStatus.cancelled:
        return 'Cancelled';
      case OfferStatus.paymentSubmitted:
        return 'Payment Submitted';
      case OfferStatus.completed:
        return 'Completed';
      case OfferStatus.disputed:
        return 'Disputed';
    }
  }

  bool _shouldShowExpiryDate(OfferStatus status) {
    return status == OfferStatus.pending ||
        status == OfferStatus.accepted ||
        status == OfferStatus.paymentSubmitted;
  }

  bool _isExpiringSoon(DateTime expiryDate) {
    final now = DateTime.now();
    final difference = expiryDate.difference(now);
    return difference.inHours < 3 && difference.isNegative == false;
  }

  bool _shouldShowActions(OfferStatus status, bool isReceived) {
    if (isReceived) {
      return status == OfferStatus.pending ||
          status == OfferStatus.paymentSubmitted;
    } else {
      return status == OfferStatus.accepted;
    }
  }

  bool _isExpired(OfferStatus status) {
    return status == OfferStatus.cancelled;
  }

  List<Widget> _buildActionButtons(
      BuildContext context, WidgetRef ref, OfferModel offer, bool isReceived) {
    if (isReceived) {
      if (offer.status == OfferStatus.pending) {
        return [
          OutlinedButton(
            onPressed: () {
              _showRespondToOfferDialog(context, ref, offer, false);
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Decline'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              _showRespondToOfferDialog(context, ref, offer, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Accept'),
          ),
        ];
      } else if (offer.status == OfferStatus.paymentSubmitted) {
        return [
          OutlinedButton(
            onPressed: () {
              _showRespondToPaymentDialog(context, ref, offer, false);
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Reject Payment'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              _showRespondToPaymentDialog(context, ref, offer, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm Payment'),
          ),
        ];
      }
    } else {
      // For made offers
      if (offer.status == OfferStatus.pending) {
        return [
          OutlinedButton(
            onPressed: () {
              _showCancelOfferDialog(context, ref, offer);
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Cancel Offer'),
          ),
        ];
      } else if (offer.status == OfferStatus.accepted) {
        return [
          OutlinedButton(
            onPressed: () {
              _showCancelOfferDialog(context, ref, offer);
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Cancel Offer'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              _showPaymentDialog(context, ref, offer);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Submit Payment'),
          ),
        ];
      }
    }
    return [];
  }

  void _showRespondToOfferDialog(
      BuildContext context, WidgetRef ref, OfferModel offer, bool accept) {
    RespondOfferDialog.show(context, offer, accept).then((result) {
      if (result == true) {
        // Refresh offers list after handling the offer
        if (accept) {
          ref.read(receivedOffersProvider.notifier).loadOffers();
        }
      }
    });
  }

  void _showRespondToPaymentDialog(
      BuildContext context, WidgetRef ref, OfferModel offer, bool confirm) {
    RespondPaymentDialog.show(context, offer, confirm).then((result) {
      if (result == true) {
        // Refresh offers list after handling the payment
        ref.read(receivedOffersProvider.notifier).loadOffers();
      }
    });
  }

  void _showPaymentDialog(
      BuildContext context, WidgetRef ref, OfferModel offer) {
    SubmitPaymentDialog.show(context, offer).then((result) {
      if (result == true) {
        // Refresh offers list after submitting payment
        ref.read(madeOffersProvider.notifier).loadOffers();
      }
    });
  }

  void _showOfferDetailsDialog(BuildContext context, WidgetRef ref) {
    final formatter = NumberFormat.currency(symbol: offer.currency);
    final screenSize = MediaQuery.of(context).size;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: screenSize.height * 0.8,
              maxWidth: screenSize.width * 0.9,
              minWidth: 280,
              minHeight: 100,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dialog header
                  Text(
                    offer.pieceTitle ?? 'Offer Details',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow(
                              'Status', _formatStatus(offer.status)),
                          _buildDetailRow('Amount',
                              '${offer.currency ?? 'USD'} ${offer.amount.toStringAsFixed(2)}'),
                          _buildDetailRow(
                            isReceived ? 'Buyer' : 'Seller',
                            isReceived ? offer.buyer : offer.seller,
                          ),
                          _buildDetailRow(
                            'Created',
                            DateFormat('MMM d, y · h:mm a')
                                .format(offer.createdAt),
                          ),
                          if (offer.paymentDetails != null &&
                              offer.paymentDetails!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 16.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Text(
                                        'Payment Details:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const Spacer(),
                                      // Copy button for convenience
                                      IconButton(
                                        icon: const Icon(Icons.copy, size: 16),
                                        tooltip: 'Copy payment details',
                                        onPressed: () {
                                          final paymentDetails =
                                              offer.paymentDetails!;
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  'Payment details copied to clipboard'),
                                              duration: Duration(seconds: 2),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(8.0),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[50],
                                      borderRadius: BorderRadius.circular(4.0),
                                      border:
                                          Border.all(color: Colors.grey[200]!),
                                    ),
                                    constraints: const BoxConstraints(
                                      minHeight: 60,
                                      maxHeight: 150,
                                    ),
                                    child: SingleChildScrollView(
                                      child: SelectableText(
                                        offer.paymentDetails!,
                                        style: TextStyle(
                                          height: 1.5,
                                          color: Colors.grey[800],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (offer.paymentDeadline != null)
                            _buildDetailRow(
                              'Payment Due',
                              DateFormat('MMM d, y · h:mm a')
                                  .format(offer.paymentDeadline!),
                            ),
                          if (offer.paymentSubmittedAt != null)
                            _buildDetailRow(
                              'Payment Submitted',
                              DateFormat('MMM d, y · h:mm a')
                                  .format(offer.paymentSubmittedAt!),
                            ),
                          if (offer.message != null &&
                              offer.message!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 16.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Message:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(offer.message!),
                                ],
                              ),
                            ),
                          // Payment proof section
                          if (offer.paymentProof != null &&
                              (offer.status == OfferStatus.paymentSubmitted ||
                                  offer.status == OfferStatus.completed ||
                                  offer.status == OfferStatus.disputed))
                            Padding(
                              padding: const EdgeInsets.only(top: 16.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Payment Proof:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  _buildPaymentProofSection(context, ref),
                                ],
                              ),
                            ),
                          // Dispute section
                          if (offer.dispute != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 16.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Dispute Information:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  _buildDetailRow('Opened By',
                                      offer.dispute!.openedBy ?? ''),
                                  _buildDetailRow(
                                      'Reason', offer.dispute!.reason ?? ''),
                                  if (offer.dispute!.openedAt != null)
                                    _buildDetailRow(
                                      'Opened At',
                                      DateFormat('MMM d, y · h:mm a')
                                          .format(offer.dispute!.openedAt!),
                                    ),
                                  if (offer.dispute!.resolvedAt != null)
                                    _buildDetailRow(
                                      'Resolved At',
                                      DateFormat('MMM d, y · h:mm a')
                                          .format(offer.dispute!.resolvedAt!),
                                    ),
                                  if (offer.dispute!.resolution != null)
                                    _buildDetailRow('Resolution',
                                        offer.dispute!.resolution!),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        runAlignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        alignment: WrapAlignment.center,
                        children: [
                          if (!isReceived &&
                              (offer.status == OfferStatus.pending ||
                                  offer.status == OfferStatus.accepted))
                            OutlinedButton(
                              onPressed: () {
                                Navigator.of(dialogContext).pop();
                                _showCancelOfferDialog(context, ref, offer);
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              child: const Text('Cancel Offer'),
                            ),
                          if (!isReceived &&
                              offer.status == OfferStatus.accepted)
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(dialogContext).pop();
                                _showPaymentDialog(context, ref, offer);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Submit Payment'),
                            ),
                          if (isReceived &&
                              offer.status == OfferStatus.pending) ...[
                            OutlinedButton(
                              onPressed: () {
                                Navigator.of(dialogContext).pop();
                                _showRespondToOfferDialog(
                                    context, ref, offer, false);
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              child: const Text('Decline'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(dialogContext).pop();
                                _showRespondToOfferDialog(
                                    context, ref, offer, true);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Accept'),
                            ),
                          ],
                          if (isReceived &&
                              offer.status == OfferStatus.paymentSubmitted) ...[
                            OutlinedButton(
                              onPressed: () {
                                Navigator.of(dialogContext).pop();
                                _showRespondToPaymentDialog(
                                    context, ref, offer, false);
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              child: const Text('Reject Payment'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(dialogContext).pop();
                                _showRespondToPaymentDialog(
                                    context, ref, offer, true);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Confirm Payment'),
                            ),
                          ],
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentProofSection(BuildContext context, WidgetRef ref) {
    return FutureBuilder<ApiResponse>(
      future: ref.read(offerRepositoryProvider).getPaymentProof(offer.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 100,
            width: double.infinity,
            alignment: Alignment.center,
            child: const CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError ||
            !snapshot.hasData ||
            !snapshot.data!.isSuccess) {
          return SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Error loading payment proof: ${snapshot.error ?? snapshot.data?.message ?? 'Unknown error'}',
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 8),
                if (offer.paymentProof != null)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => _launchUrl(offer.paymentProof!),
                      child: const Text('View Payment Proof'),
                    ),
                  ),
              ],
            ),
          );
        }

        final proofUrl =
            snapshot.data!.data?['payment_proof_url'] ?? offer.paymentProof;

        if (proofUrl == null) {
          return const Text('No payment proof available');
        }

        return SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  proofUrl,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      width: double.infinity,
                      color: Colors.grey[200],
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.broken_image,
                              size: 40, color: Colors.grey),
                          const SizedBox(height: 8),
                          Text('Failed to load image: $error'),
                        ],
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 200,
                      width: double.infinity,
                      color: Colors.grey[200],
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _showFullScreenImage(context, proofUrl),
                  child: const Text('View Full Image'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('Payment Proof')),
          body: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.broken_image,
                          size: 80, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text('Failed to load image: $error'),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _launchUrl(String url) async {
    // This would launch the URL in a web browser
    // You'll need to add the url_launcher package for this
    print('Launching URL: $url');
  }

  // Add this method to handle offer cancellation
  void _showCancelOfferDialog(
      BuildContext context, WidgetRef ref, OfferModel offer) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cancel Offer'),
          content: Text(
            'Are you sure you want to cancel your offer for ${offer.pieceTitle ?? 'this piece'}? '
            'This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('No'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final result = await ref
                    .read(madeOffersProvider.notifier)
                    .cancelOffer(offer.id);

                if (result) {
                  ref.read(madeOffersProvider.notifier).loadOffers();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Yes, Cancel'),
            ),
          ],
        );
      },
    );
  }
}
