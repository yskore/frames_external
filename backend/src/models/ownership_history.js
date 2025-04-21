const mongoose = require('mongoose');

const ownershipHistorySchema = new mongoose.Schema({
    piece_id: {
        type: String,
        required: true,
        ref: 'Piece'
    },
    owner: {
        type: String,
        required: true,
        ref: 'user_basic'
    },
    transfer_type: {
        type: String,
        enum: [
            'platform_transfer',             
            'marketplace_sale',          // Normal sale through marketplace
            'dispute_resolution',        // Transfer after dispute resolution
            'admin_transfer',           // Administrative transfer
        ],
        required: true
    },
    previous_owner: {
        type: String,
        ref: 'user_basic'
    },
    related_offer: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Offer'
    },
    transfer_price: {
        type: Number,
        min: 0
    },
    start_date: {
        type: Date,
        required: true,
        default: Date.now
    },
    end_date: Date
}, { timestamps: true }); // Add timestamps for better tracking

// Add compound index for querying ownership history
ownershipHistorySchema.index({ piece_id: 1, start_date: -1 });

// Add static method to get piece ownership history
ownershipHistorySchema.statics.getPieceHistory = async function(pieceId) {
    return this.find({ piece_id: pieceId })
              .sort({ start_date: -1 })
              .populate('related_offer', 'status amount')
              .exec();
};

// Add static method to get current owner
ownershipHistorySchema.statics.getCurrentOwner = async function(pieceId) {
    return this.findOne({ piece_id: pieceId, end_date: null })
              .select('owner start_date')
              .exec();
};

const OwnershipHistory = mongoose.model('OwnershipHistory', ownershipHistorySchema);
module.exports = OwnershipHistory;
