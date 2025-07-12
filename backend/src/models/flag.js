const mongoose = require('mongoose');

const flagSchema = new mongoose.Schema({
    Flag_id: {
        type: String,
        required: true,
        unique: true
    },
    Flag_type: {
        type: String,
        enum: ['IN', 'PI'], // IN: inappropriate, PI: piracy
        required: true
    },
    Flag_raised_by: {
        type: String,
        required: true,
        ref: 'user_basic'
    },
    Piece_id: {
        type: String,
        required: true,
        ref: 'Piece'
    },
    Piece_owner: {
        type: String,
        required: true,
        ref: 'user_basic'
    },
    timestamp: {
        type: Date,
        default: Date.now,
        required: true
    },
    evidence_image_url: {
        type: String,
        default: ''
    }
}, { timestamps: true });

// Index for efficient querying
flagSchema.index({ Piece_id: 1, Flag_type: 1 });
flagSchema.index({ Piece_owner: 1 });
flagSchema.index({ Flag_raised_by: 1 });

flagSchema.statics.countFlagsByPieceAndType = async function(pieceId, flagType, session = null) {
    const query = this.countDocuments({ Piece_id: pieceId, Flag_type: flagType });
    return session ? query.session(session) : query;
};

flagSchema.statics.hasUserFlaggedPiece = async function(pieceId, username) {
    const flag = await this.findOne({ 
        Piece_id: pieceId, 
        Flag_raised_by: username 
    });
    return !!flag;
};

const Flag = mongoose.model('Flag', flagSchema);
module.exports = Flag;