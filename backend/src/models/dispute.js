const mongoose = require('mongoose');

const disputeSchema = new mongoose.Schema({
    Dispute_id: {
        type: String,
        required: true,
        unique: true
    },
    Flag_id: {
        type: String,
        required: true,
        ref: 'Flag'
    },
    Flag_type: {
        type: String,
        enum: ['IN', 'PI'], // IN: inappropriate, PI: piracy
        required: true
    },
    Piece_owner: {
        type: String,
        required: true,
        ref: 'user_basic'
    },
    Piece_id: {
        type: String,
        required: true,
        ref: 'Piece'
    },
    Piece_title: {
        type: String,
        required: true
    },
    Dispute_status: {
        type: String,
        enum: ['Raised', 'Accepted', 'Rejected', 'Cancelled'],
        default: 'Raised',
        required: true
    },
    Ownership_evidence: {
        type: String, // image URL
        required: false
    },
    Comments: {
        type: String,
        required: false,
        default: ''
    },
    timestamp: {
        type: Date,
        default: Date.now,
        required: true
    },
    resolved_at: {
        type: Date
    },
    resolved_by: {
        type: String,
        ref: 'user_basic'
    },
    user_responded: {
        type: Boolean,
        default: true // Set to true when dispute is created
    }
}, { timestamps: true });

// Index for efficient querying
disputeSchema.index({ Piece_id: 1 });
disputeSchema.index({ Piece_owner: 1 });
disputeSchema.index({ Dispute_status: 1 });
disputeSchema.index({ Flag_type: 1 });

const Dispute = mongoose.model('Dispute', disputeSchema);
module.exports = Dispute;