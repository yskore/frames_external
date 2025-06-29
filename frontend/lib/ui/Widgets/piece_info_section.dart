// piece_info_section.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:frames_app/ui/Widgets/ownership_selection.dart';
import 'package:frames_app/models/piece_model.dart';
import 'package:currency_picker/currency_picker.dart';

class PieceInfoSection extends StatelessWidget {
  final Piece piece;
  final bool isEditing;
  final TextEditingController nameController;
  final TextEditingController descriptionController;
  final TextEditingController priceController;
  final TextEditingController currencyController;
  final TextEditingController paymentDetailsController;
  final bool isLoadingAnchorDetails;
  final DateTime? anchorExpireTime;
  final String ownership;
  final Function(String) onOwnershipChanged;
  final Function(bool) onForSaleChanged;
    final Function(bool) onHiddenChanged; // Add this
  final Function(int) onShowRadiusChanged;
  final BuildContext context; // Add context parameter

  const PieceInfoSection({
    Key? key,
    required this.piece,
    required this.isEditing,
    required this.nameController,
    required this.descriptionController,
    required this.priceController,
    required this.currencyController, // Add this parameter
    required this.paymentDetailsController,
    required this.isLoadingAnchorDetails,
    this.anchorExpireTime,
    required this.ownership,
    required this.onOwnershipChanged,
    required this.onForSaleChanged,
     required this.onHiddenChanged, // Add this
    required this.onShowRadiusChanged,
    required this.context, // Add this parameter
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEditableInfoRow('Piece Name', nameController),
          _buildInfoRow('Piece Owner', piece.pieceOwner),
          _buildEditableInfoRow('Description', descriptionController),
          _buildInfoRow('Likes', piece.pieceLikes.toString()),
          _buildInfoRow('Impressions', piece.pieceImpressions.toString() ?? '0'),
          _buildInfoRow('Live Status', piece.liveStatus ? 'Live' : 'Not Live'),
          _buildExpiryTimeInfo(),
          Row(
            children: [
              const Text('For Sale: ',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Switch(
                value: piece.pieceForSale,
                onChanged: isEditing
                    ? (value) => onForSaleChanged(value)
                    : null,
              ),
            ],
          ),
          if (piece.pieceForSale) ...[
            if (isEditing) ...[
              _buildCurrencySelector(), // Add this for currency selection
              const SizedBox(height: 5),
            ],
            _buildEditableInfoRow('Price', priceController),
            _buildEditableInfoRow('Payment Details', paymentDetailsController)
          ],
          _buildInfoRow(
              'Creation Date',
              DateFormat('yyyy-MM-dd')
                  .format(piece.pieceCreationDate)),
          
          const SizedBox(height: 16),
          OwnershipSelectionWidget(
            initialValue: ownership,
            onChanged: onOwnershipChanged,
            isEditing: isEditing,
          ),
           Row(
    children: [
      const Text('Hidden Piece: ', style: TextStyle(fontWeight: FontWeight.bold)),
      Switch(
        value: piece.isHidden,
        onChanged: onHiddenChanged, // Add this callback
      ),
    ],
  ),
   // Show radius slider when hidden
  if (piece.isHidden) ...[
    const SizedBox(height: 8),
    const Text('Location Display (0-500m)', style: TextStyle(fontWeight: FontWeight.w500)),
    Row(
      children: [
        Expanded(
          child: Slider(
            value: piece.showRadius.toDouble(),
            min: 0,
            max: 500,
            divisions: 10,
            label: piece.showRadius == 0 ? 'Exact location' : '${piece.showRadius}m radius',
            onChanged: (value) => onShowRadiusChanged(value.round()), // Add this callback
          ),
        ),
        SizedBox(
          width: 100,
          child: Text(
            piece.showRadius == 0 ? 'Exact location' : '${piece.showRadius}m radius',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
  ],
],
        
      ),
    );
  }

  // Add currency selector widget
  Widget _buildCurrencySelector() {
    return Row(
      children: [
        const Text('Currency: ', style: TextStyle(fontWeight: FontWeight.bold)),
        Expanded(
          child: GestureDetector(
            onTap: isEditing ? _openCurrencyPicker : null,
            child: AbsorbPointer(
              child: TextField(
                controller: currencyController,
                decoration: InputDecoration(
                  border: isEditing ? null : InputBorder.none,
                  suffixIcon: isEditing ? const Icon(Icons.arrow_drop_down) : null,
                ),
                readOnly: true,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _openCurrencyPicker() {
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

  // Remaining widget methods...
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildEditableInfoRow(String label, TextEditingController controller) {

      // Special case for Payment Details to make it multi-line
  if (label == 'Payment Details') {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            maxLines: 4,  // This makes it a multi-line text field
            decoration: InputDecoration(
              border: isEditing ? const OutlineInputBorder() : InputBorder.none,
            ),
            readOnly: !isEditing,
          ),
        ],
      ),
    );
  }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                border: isEditing ? null : InputBorder.none,
              ),
              readOnly: !isEditing,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpiryTimeInfo() {
    if (!piece.liveStatus) {
      return const SizedBox.shrink(); // Don't show for non-live pieces
    }

    if (isLoadingAnchorDetails) {
      return Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Center(
          child: CircularProgressIndicator(strokeWidth: 2.0),
        ),
      );
    }

    if (anchorExpireTime == null) {
      return Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Text(
          'Expiry time not available',
          style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
        ),
      );
    }

    // Calculate days remaining
    final now = DateTime.now();
    final difference = anchorExpireTime!.difference(now);
    final daysRemaining = difference.inDays;

    // Choose color based on days remaining
    Color textColor = Colors.green;
    if (daysRemaining < 30) {
      textColor = Colors.orange;
    }
    if (daysRemaining < 7) {
      textColor = Colors.red;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        children: [
          const Text('Anchor Expires: ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('yyyy-MM-dd').format(anchorExpireTime!),
                ),
                Text(
                  '$daysRemaining days remaining',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}