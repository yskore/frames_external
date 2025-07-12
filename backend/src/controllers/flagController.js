const Flag = require('../models/flag');
const Dispute = require('../models/dispute');
const Piece = require('../models/pieces');
const user_profile = require('../models/user_profile');
const mongoose = require('mongoose');
const { v4: uuidv4 } = require('uuid');
const { sendFlagNotification } = require('../utils/notificationUtils');

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
        const flagCount = await Flag.countDocuments({ 
            Piece_id: pieceId, 
            Flag_type: flagType 
        }).session(session);
        console.log(`[FLAG DEBUG] Piece ${pieceId} - Flag type ${flagType} count: ${flagCount}`);

        // Check if threshold reached (3 flags)
        if (flagCount >= 3) {
            console.log(`[FLAG DEBUG] Threshold reached for piece ${pieceId}, flagType: ${flagType}, count: ${flagCount}`);
            await this.handleFlagThresholdReached(piece, flagType, session);
        } else {
            console.log(`[FLAG DEBUG] Threshold not reached for piece ${pieceId}, flagType: ${flagType}, count: ${flagCount}/3`);
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

    console.log(`[FLAG DEBUG] handleFlagThresholdReached called - Piece: ${pieceId}, FlagType: ${flagType}, Owner: ${pieceOwner}`);

    if (flagType === 'IN') {
        console.log(`[FLAG DEBUG] Processing inappropriate flag threshold for piece ${pieceId}`);
        await this.handleInappropriateThreshold(piece, session);
    } else if (flagType === 'PI') {
        console.log(`[FLAG DEBUG] Processing piracy flag threshold for piece ${pieceId}`);
        await this.handlePiracyThreshold(piece, session);
    }
    
    console.log(`[FLAG DEBUG] Completed threshold handling for piece ${pieceId}`);
};

exports.handleInappropriateThreshold = async (piece, session) => {
    console.log(`[FLAG DEBUG] handleInappropriateThreshold - Starting for piece ${piece.Piece_id}`);
    
    // Send notification to piece owner
    sendFlagNotification({
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
    console.log(`[FLAG DEBUG] Updating piece ${piece.Piece_id} with expiration: ${expirationTime}, flag_type: IN, flag_status: pending_action`);
    
    const updateResult = await Piece.findOneAndUpdate(
        { Piece_id: piece.Piece_id },
        { 
            flag_expiration: expirationTime,
            flag_type: 'IN',
            flag_status: 'pending_action'
        },
        { session, new: true }
    );
    
    console.log(`[FLAG DEBUG] Update result for piece ${piece.Piece_id}:`, updateResult ? 'SUCCESS' : 'FAILED');
    if (updateResult) {
        console.log(`[FLAG DEBUG] Updated piece status - flag_status: ${updateResult.flag_status}, flag_type: ${updateResult.flag_type}`);
    }
};

exports.handlePiracyThreshold = async (piece, session) => {
    console.log(`[FLAG DEBUG] handlePiracyThreshold - Starting for piece ${piece.Piece_id}, current ownership: ${piece.ownership}`);
    
    // Check ownership status
    if (piece.ownership === '00') {
        console.log(`[FLAG DEBUG] Piece ${piece.Piece_id} already has ownership '00', no action needed`);
        return;
    }

    // Send notification to piece owner
    sendFlagNotification({
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
    console.log(`[FLAG DEBUG] Updating piece ${piece.Piece_id} with flag_type: PI, flag_status: pending_action`);
    
    const updateResult = await Piece.findOneAndUpdate(
        { Piece_id: piece.Piece_id },
        { 
            flag_type: 'PI',
            flag_status: 'pending_action'
        },
        { session, new: true }
    );
    
    console.log(`[FLAG DEBUG] Update result for piece ${piece.Piece_id}:`, updateResult ? 'SUCCESS' : 'FAILED');
    if (updateResult) {
        console.log(`[FLAG DEBUG] Updated piece status - flag_status: ${updateResult.flag_status}, flag_type: ${updateResult.flag_type}`);
    }
};

exports.respondToFlag = async (req, res) => {
    const session = await mongoose.startSession();
    session.startTransaction();

    try {
        const { pieceId } = req.params;
        const { action, evidence, comments } = req.body; // action: 'accept' or 'dispute'
        const username = req.user.username;
        
        // Get evidence image URL from uploaded file
        const evidence_image_url = req.file ? req.file.location : null;

        const piece = await Piece.findOne({ 
            Piece_id: pieceId,
            Piece_owner: username,
            flag_status: 'pending_action'
        }).session(session);

        if (!piece) {
            throw new Error('Piece not found or not flagged, or you are not the owner');
        }

        // Check if user has already responded (has an existing dispute)
        const existingDispute = await Dispute.findOne({
            Piece_id: pieceId,
            Piece_owner: username,
            Dispute_status: 'Raised'
        }).session(session);

        if (existingDispute && action === 'dispute') {
            throw new Error('You have already disputed the flags for this piece. Please wait for admin review.');
        }

        if (piece.flag_type === 'IN') {
            await this.handleInappropriateResponse(piece, action, evidence, comments, evidence_image_url, session);
        } else if (piece.flag_type === 'PI') {
            await this.handlePiracyResponse(piece, action, evidence, comments, evidence_image_url, session);
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

exports.handleInappropriateResponse = async (piece, action, evidence, comments, evidence_image_url, session) => {
    if (action === 'accept') {
        // Delete the piece
        await this.deletePieceForFlag(piece, session);
    } else if (action === 'dispute') {
        // Create dispute record
        await this.createDispute(piece, 'IN', evidence, comments, evidence_image_url, session);
    } else {
        throw new Error('Invalid action. Must be "accept" or "dispute"');
    }
};

exports.handlePiracyResponse = async (piece, action, evidence, comments, evidence_image_url, session) => {
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
        await this.createDispute(piece, 'PI', evidence, comments, evidence_image_url, session);
    } else {
        throw new Error('Invalid action. Must be "accept" or "dispute"');
    }
};

exports.createDispute = async (piece, flagType, evidence, comments, evidence_image_url, session) => {
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
        Evidence_image_url: evidence_image_url || '',
        timestamp: new Date(),
        user_responded: true // Mark that user has responded
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
    sendFlagNotification({
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
            $or: [
                { flag_status: { $in: ['pending_action', 'disputed'] } },
                { 
                    'dispute_resolution.acknowledged_by_owner': false,
                    'dispute_resolution.status': { $exists: true }
                }
            ]
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

exports.acknowledgeDisputeResolution = async (req, res) => {
    try {
        const { pieceId } = req.params;
        const username = req.user.username;

        const piece = await Piece.findOne({
            Piece_id: pieceId,
            Piece_owner: username,
            'dispute_resolution.status': { $exists: true },
            'dispute_resolution.acknowledged_by_owner': false
        });

        if (!piece) {
            return res.status(404).json({
                success: false,
                message: 'No unacknowledged dispute resolution found for this piece'
            });
        }

        await Piece.findOneAndUpdate(
            { Piece_id: pieceId },
            { 'dispute_resolution.acknowledged_by_owner': true },
            { new: true }
        );

        res.status(200).json({
            success: true,
            message: 'Dispute resolution acknowledged successfully',
            data: {
                pieceId: pieceId,
                resolutionStatus: piece.dispute_resolution.status
            }
        });

    } catch (error) {
        console.error('Error acknowledging dispute resolution:', error);
        res.status(500).json({
            success: false,
            message: error.message || 'Failed to acknowledge dispute resolution'
        });
    }
};