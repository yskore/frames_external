const Flag = require('../models/flag');
const Dispute = require('../models/dispute');
const Piece = require('../models/pieces');
const user_profile = require('../models/user_profile');
const mongoose = require('mongoose');
const { v4: uuidv4 } = require('uuid');
const { sendBothNotifications } = require('../utils/notificationUtils');

exports.flagPiece = async (req, res) => {
    const session = await mongoose.startSession();
    session.startTransaction();

    try {
        const { pieceId } = req.params;
        const { flagType } = req.body; // 'IN' or 'PI'
        const username = req.user.username;

        // Validate flag type
        if (!['IN', 'PI'].includes(flagType)) {
            throw new Error('Invalid flag type. Must be "IN" (inappropriate) or "PI" (piracy)');
        }

        // Get piece details
        const piece = await Piece.findOne({ Piece_id: pieceId }).session(session);
        if (!piece) {
            throw new Error('Piece not found');
        }

        // Prevent users from flagging their own pieces
        if (piece.Piece_owner === username) {
            throw new Error('Cannot flag your own piece');
        }

        // Check if user already flagged this piece
        const existingFlag = await Flag.hasUserFlaggedPiece(pieceId, username);
        if (existingFlag) {
            throw new Error('You have already flagged this piece');
        }

        // Create flag record
        const flagId = uuidv4();
        const newFlag = new Flag({
            Flag_id: flagId,
            Flag_type: flagType,
            Flag_raised_by: username,
            Piece_id: pieceId,
            Piece_owner: piece.Piece_owner,
            timestamp: new Date()
        });

        await newFlag.save({ session });

        // Count total flags of this type for the piece
        const flagCount = await Flag.countFlagsByPieceAndType(pieceId, flagType);

        // Check if threshold reached (3 flags)
        if (flagCount >= 3) {
            await this.handleFlagThresholdReached(piece, flagType, session);
        }

        await session.commitTransaction();

        res.status(201).json({
            success: true,
            message: 'Flag submitted successfully',
            data: {
                flag: newFlag,
                totalFlags: flagCount
            }
        });

    } catch (error) {
        if (session.inTransaction()) {
            await session.abortTransaction();
        }
        console.error('Error flagging piece:', error);
        res.status(500).json({
            success: false,
            message: error.message || 'Failed to flag piece'
        });
    } finally {
        session.endSession();
    }
};

exports.handleFlagThresholdReached = async (piece, flagType, session) => {
    const pieceId = piece.Piece_id;
    const pieceOwner = piece.Piece_owner;

    if (flagType === 'IN') {
        // Inappropriate flag threshold reached
        await this.handleInappropriateThreshold(piece, session);
    } else if (flagType === 'PI') {
        // Piracy flag threshold reached
        await this.handlePiracyThreshold(piece, session);
    }
};

exports.handleInappropriateThreshold = async (piece, session) => {
    // Send notification to piece owner
    sendBothNotifications({
        userId: piece.Piece_owner,
        notificationType: 'piece_flagged_inappropriate',
        data: {
            pieceId: piece.Piece_id,
            pieceTitle: piece.Piece_title,
            flagType: 'inappropriate',
            message: 'This piece has been flagged as inappropriate',
            timestamp: new Date().toISOString()
        },
        priority: 'high'
    }).catch(err => console.error('Error sending notification:', err));

    // Set piece expiration for auto-deletion after 48 hours
    const expirationTime = new Date(Date.now() + 48 * 60 * 60 * 1000); // 48 hours
    await Piece.findOneAndUpdate(
        { Piece_id: piece.Piece_id },
        { 
            flag_expiration: expirationTime,
            flag_type: 'IN',
            flag_status: 'pending_action'
        },
        { session }
    );
};

exports.handlePiracyThreshold = async (piece, session) => {
    // Check ownership status
    if (piece.ownership === '00') {
        // User already acknowledges they don't own the content, no action needed
        return;
    }

    // Send notification to piece owner
    sendBothNotifications({
        userId: piece.Piece_owner,
        notificationType: 'piece_flagged_piracy',
        data: {
            pieceId: piece.Piece_id,
            pieceTitle: piece.Piece_title,
            flagType: 'piracy',
            message: 'This piece has been flagged for piracy',
            timestamp: new Date().toISOString()
        },
        priority: 'high'
    }).catch(err => console.error('Error sending notification:', err));

    // Set piece for piracy action
    await Piece.findOneAndUpdate(
        { Piece_id: piece.Piece_id },
        { 
            flag_type: 'PI',
            flag_status: 'pending_action'
        },
        { session }
    );
};

exports.respondToFlag = async (req, res) => {
    const session = await mongoose.startSession();
    session.startTransaction();

    try {
        const { pieceId } = req.params;
        const { action, evidence, comments } = req.body; // action: 'accept' or 'dispute'
        const username = req.user.username;

        const piece = await Piece.findOne({ 
            Piece_id: pieceId,
            Piece_owner: username,
            flag_status: 'pending_action'
        }).session(session);

        if (!piece) {
            throw new Error('Piece not found or not flagged, or you are not the owner');
        }

        if (piece.flag_type === 'IN') {
            await this.handleInappropriateResponse(piece, action, evidence, comments, session);
        } else if (piece.flag_type === 'PI') {
            await this.handlePiracyResponse(piece, action, evidence, comments, session);
        }

        await session.commitTransaction();

        res.status(200).json({
            success: true,
            message: `Flag response processed successfully`
        });

    } catch (error) {
        if (session.inTransaction()) {
            await session.abortTransaction();
        }
        console.error('Error responding to flag:', error);
        res.status(500).json({
            success: false,
            message: error.message || 'Failed to process flag response'
        });
    } finally {
        session.endSession();
    }
};

exports.handleInappropriateResponse = async (piece, action, evidence, comments, session) => {
    if (action === 'accept') {
        // Delete the piece
        await this.deletePieceForFlag(piece, session);
    } else if (action === 'dispute') {
        // Create dispute record
        await this.createDispute(piece, 'IN', evidence, comments, session);
    } else {
        throw new Error('Invalid action. Must be "accept" or "dispute"');
    }
};

exports.handlePiracyResponse = async (piece, action, evidence, comments, session) => {
    if (action === 'accept') {
        // Change ownership to "00"
        await Piece.findOneAndUpdate(
            { Piece_id: piece.Piece_id },
            { 
                ownership: '00',
                flag_status: 'resolved',
                flag_type: null
            },
            { session }
        );
    } else if (action === 'dispute') {
        // Create dispute record
        await this.createDispute(piece, 'PI', evidence, comments, session);
    } else {
        throw new Error('Invalid action. Must be "accept" or "dispute"');
    }
};

exports.createDispute = async (piece, flagType, evidence, comments, session) => {
    const disputeId = uuidv4();
    
    const dispute = new Dispute({
        Dispute_id: disputeId,
        Flag_id: `${piece.Piece_id}_${flagType}`, // Reference to the flag
        Flag_type: flagType,
        Piece_owner: piece.Piece_owner,
        Piece_id: piece.Piece_id,
        Piece_title: piece.Piece_title,
        Dispute_status: 'Raised',
        Ownership_evidence: evidence || '',
        Comments: comments || '',
        timestamp: new Date()
    });

    await dispute.save({ session });

    // Update piece status
    await Piece.findOneAndUpdate(
        { Piece_id: piece.Piece_id },
        { 
            flag_status: 'disputed',
            dispute_id: disputeId
        },
        { session }
    );
};

exports.deletePieceForFlag = async (piece, session) => {
    // Mark piece as deleted due to flag
    await Piece.findOneAndUpdate(
        { Piece_id: piece.Piece_id },
        { 
            flag_status: 'deleted',
            deleted_at: new Date(),
            live_status: false
        },
        { session }
    );

    // Send notification to owner
    sendBothNotifications({
        userId: piece.Piece_owner,
        notificationType: 'piece_deleted_flag',
        data: {
            pieceId: piece.Piece_id,
            pieceTitle: piece.Piece_title,
            reason: 'flagged_content',
            timestamp: new Date().toISOString()
        }
    }).catch(err => console.error('Error sending notification:', err));
};

// Auto-delete expired flagged pieces (run as scheduled job)
exports.handleExpiredFlags = async () => {
    const session = await mongoose.startSession();
    session.startTransaction();

    try {
        const now = new Date();
        const expiredPieces = await Piece.find({
            flag_expiration: { $lte: now },
            flag_status: 'pending_action'
        }).session(session);

        for (const piece of expiredPieces) {
            await this.deletePieceForFlag(piece, session);
        }

        await session.commitTransaction();
        return { success: true, deletedCount: expiredPieces.length };

    } catch (error) {
        if (session.inTransaction()) {
            await session.abortTransaction();
        }
        console.error('Error handling expired flags:', error);
        return { success: false, error: error.message };
    } finally {
        session.endSession();
    }
};

exports.getFlaggedPieces = async (req, res) => {
    try {
        const username = req.user.username;

        const flaggedPieces = await Piece.find({
            Piece_owner: username,
            flag_status: { $in: ['pending_action', 'disputed'] }
        });

        res.status(200).json({
            success: true,
            data: { flaggedPieces }
        });

    } catch (error) {
        console.error('Error fetching flagged pieces:', error);
        res.status(500).json({
            success: false,
            message: error.message || 'Failed to fetch flagged pieces'
        });
    }
};