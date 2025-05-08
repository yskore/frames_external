const mongoose = require('mongoose');

const offerSchema = new mongoose.Schema({
    piece_id: {
        type: String,
        required: true,
        ref: 'Piece'
    },
    piece_title: {
        type: String,
        default: 'Untitled'  
    },
    buyer: {
        type: String,
        required: true,
        ref: 'user_basic'
    },
    seller: {
        type: String,
        required: true,
        ref: 'user_basic'
    },
    amount: {
        type: Number,
        required: true,
        min: 0
    },
    currency: {
        type: String,
        default: 'USD'
    },
    payment_details: {
        type: String
    },
    status: {
        type: String,
        enum: ['pending', 'accepted', 'rejected', 'cancelled', 'payment_submitted', 'completed', 'disputed'],
        default: 'pending'
    },
    payment_deadline: {
        type: Date
    },
    payment_proof: {
        type: String
    },
    piece_status: {
        type: String,
        enum: ['available', 'in_progress', 'sold'],
        default: 'available'
    },
    seller_confirmation_deadline: {
        type: Date
    },
    seller_grace_deadline: {
        type: Date
    },
    payment_submitted_at: {
        type: Date
    },
    dispute: {
        opened_by: {
            type: String,
            ref: 'user_basic'
        },
        reason: String,
        opened_at: Date,
        resolved_at: Date,
        resolution: String
    },
    created_at: {
        type: Date,
        default: Date.now
    },
    updated_at: {
        type: Date,
        default: Date.now
    }
});

// Add index for finding offers by piece and buyer
offerSchema.index({ piece_id: 1, buyer: 1 });
// Add index for finding offers by seller
offerSchema.index({ seller: 1 });
// Add index for finding active offers for a piece
offerSchema.index({ piece_id: 1, status: 1 });
// Add index for payment deadline monitoring
offerSchema.index({ status: 1, payment_deadline: 1 });

// Add static method to check piece availability
offerSchema.statics.checkPieceAvailability = async function(piece_id) {
    const activeOffer = await this.findOne({
        piece_id: piece_id,
        status: { $in: ['accepted', 'payment_submitted', 'disputed'] }
    });
    return !activeOffer;
};

// Add static method to check expired confirmations
offerSchema.statics.checkExpiredConfirmations = async function() {
    const now = new Date();
    const expiredFirstWindow = await this.find({
        status: 'payment_submitted',
        seller_confirmation_deadline: { $lt: now },
        seller_grace_deadline: { $exists: false }
    });
    
    const expiredSecondWindow = await this.find({
        status: 'payment_submitted',
        seller_grace_deadline: { $lt: now }
    });

    return { expiredFirstWindow, expiredSecondWindow };
};

// Middleware to update piece status when offer is accepted
offerSchema.pre('save', async function(next) {
    if (this.isModified('status') && this.status === 'accepted') {
        // Set all other offers for this piece to cancelled
        await this.constructor.updateMany(
            {
                piece_id: this.piece_id,
                _id: { $ne: this._id },
                status: 'pending'
            },
            {
                status: 'cancelled',
                piece_status: 'in_progress'
            }
        );
        this.piece_status = 'in_progress';
    }
    next();
});

const Offer = mongoose.model('Offer', offerSchema);
module.exports = Offer;
