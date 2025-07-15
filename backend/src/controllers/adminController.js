const Offer = require("../models/offer");
const Piece = require("../models/pieces");
const OwnershipHistory = require("../models/ownership_history");
const user_profile = require("../models/user_profile");
const Dispute = require("../models/dispute");
const mongoose = require("mongoose");
const { sendBothNotifications, sendFlagNotification } = require('../utils/notificationUtils');

exports.getDisputedOffers = async (req, res) => {
    try {
        const disputedOffers = await Offer.find({
            status: "disputed",
        }).sort({ "dispute.opened_at": -1 });

        const detailedDisputes = disputedOffers.map((offer) => ({
            offerId: offer._id,
            pieceId: offer.piece_id,
            buyer: offer.buyer,
            seller: offer.seller,
            amount: offer.amount,
            disputeDetails: {
                openedBy: offer.dispute.opened_by,
                reason: offer.dispute.reason,
                openedAt: offer.dispute.opened_at,
                resolvedAt: offer.dispute.resolved_at,
                resolution: offer.dispute.resolution,
            },
            paymentProof: offer.payment_proof,
            createdAt: offer.created_at,
        }));

        res.status(200).json({
            success: true,
            data: { disputes: detailedDisputes },
        });
    } catch (error) {
        console.error("Error fetching disputed offers:", error);
        res.status(500).json({
            success: false,
            message: error.message || "Failed to fetch disputed offers",
        });
    }
};

exports.resolveDispute = async (req, res) => {
    const session = await mongoose.startSession();
    session.startTransaction();

    try {
        const { offerId } = req.params;
        const { resolution, transferOwnership, newOwner } = req.body;

        const offer = await Offer.findOne({
            _id: offerId,
            status: "disputed",
        }).session(session);

        if (!offer) {
            throw new Error("Disputed offer not found");
        }

        offer.dispute.resolution = resolution;
        offer.dispute.resolved_at = new Date();
        offer.status = "completed";

        if (transferOwnership) {
            const piece = await Piece.findOne({ Piece_id: offer.piece_id }).session(session);

            if (piece && piece.live_status) {
                await user_profile.findOneAndUpdate(
                    { username: offer.seller },
                    { $inc: { Live_pieces: -1 } },
                    { session }
                );

                await user_profile.findOneAndUpdate(
                    { username: newOwner },
                    { $inc: { Live_pieces: 1 } },
                    { session, upsert: true }
                );
            }

            // Create ownership record
            const ownershipRecord = new OwnershipHistory({
                piece_id: offer.piece_id,
                owner: newOwner,
                transfer_type: "dispute_resolution",
                previous_owner: offer.seller,
                related_offer: offer._id,
                transfer_price: offer.amount,
                start_date: new Date(),
            });
            await ownershipRecord.save({ session });

            // Update piece ownership
            await Piece.findOneAndUpdate(
                { Piece_id: offer.piece_id },
                {
                    Piece_owner: newOwner,
                    temporary_status: "normal",
                    pending_owner: null,
                    Piece_for_sale: false,
                },
                { session }
            );
        }

        await offer.save({ session });
        await session.commitTransaction();

        res.status(200).json({
            success: true,
            message: "Dispute resolved successfully",
            data: { offer },
        });
    } catch (error) {
        if (session.inTransaction()) {
            await session.abortTransaction();
        }
        console.error("Error resolving dispute:", error);
        res.status(500).json({
            success: false,
            message: error.message || "Failed to resolve dispute",
        });
    } finally {
        session.endSession();
    }
};

exports.getFlagDisputes = async (req, res) => {
    try {
        const disputes = await Dispute.find({
            Dispute_status: 'Raised'
        }).sort({ timestamp: -1 });

        res.status(200).json({
            success: true,
            data: { disputes }
        });
    } catch (error) {
        console.error("Error fetching flag disputes:", error);
        res.status(500).json({
            success: false,
            message: error.message || "Failed to fetch flag disputes",
        });
    }
};

exports.resolveFlagDispute = async (req, res) => {
    const session = await mongoose.startSession();
    session.startTransaction();

    try {
        const { disputeId } = req.params;
        const { decision } = req.body; // 'accept' or 'reject'
        const adminUsername = req.user.username;

        const dispute = await Dispute.findOne({
            Dispute_id: disputeId,
            Dispute_status: 'Raised'
        }).session(session);

        if (!dispute) {
            throw new Error("Flag dispute not found or already resolved");
        }

        const piece = await Piece.findOne({ 
            Piece_id: dispute.Piece_id 
        }).session(session);

        if (!piece) {
            throw new Error("Associated piece not found");
        }

        if (decision === 'accept') {
            // Accept dispute - keep the piece, remove flag status
            dispute.Dispute_status = 'Accepted';
            await Piece.findOneAndUpdate(
                { Piece_id: dispute.Piece_id },
                { 
                    flag_status: 'resolved',
                    flag_type: null,
                    dispute_resolution: {
                        status: 'accepted',
                        resolved_at: new Date(),
                        acknowledged_by_owner: false
                    },
                    $unset: { flag_expiration: 1, dispute_id: 1 }
                },
                { session }
            );

            // Send notification to piece owner
            sendFlagNotification({
                userId: dispute.Piece_owner,
                notificationType: 'dispute_accepted',
                data: {
                    disputeId: dispute.Dispute_id,
                    pieceId: dispute.Piece_id,
                    pieceTitle: dispute.Piece_title,
                    flagType: dispute.Flag_type,
                    timestamp: new Date().toISOString()
                }
            }).catch(err => console.error('Error sending notification:', err));

        } else if (decision === 'reject') {
            // Reject dispute - completely delete the piece from database
            dispute.Dispute_status = 'Rejected';
            
            // Update user's live pieces count if the piece was live
            if (piece.live_status) {
                await user_profile.findOneAndUpdate(
                    { username: piece.Piece_owner },
                    { $inc: { Live_pieces: -1 } },
                    { session }
                );
            }

            // Send notification to piece owner before deletion
            sendFlagNotification({
                userId: dispute.Piece_owner,
                notificationType: 'dispute_rejected',
                data: {
                    disputeId: dispute.Dispute_id,
                    pieceId: dispute.Piece_id,
                    pieceTitle: dispute.Piece_title,
                    flagType: dispute.Flag_type,
                    timestamp: new Date().toISOString()
                }
            }).catch(err => console.error('Error sending notification:', err));

            // Completely delete the piece from database
            await Piece.findOneAndDelete(
                { Piece_id: dispute.Piece_id },
                { session }
            );

        } else {
            throw new Error("Invalid decision. Must be 'accept' or 'reject'");
        }

        dispute.resolved_at = new Date();
        dispute.resolved_by = adminUsername;
        await dispute.save({ session });

        await session.commitTransaction();

        res.status(200).json({
            success: true,
            message: `Flag dispute ${decision}ed successfully`,
            data: { dispute }
        });

    } catch (error) {
        if (session.inTransaction()) {
            await session.abortTransaction();
        }
        console.error("Error resolving flag dispute:", error);
        res.status(500).json({
            success: false,
            message: error.message || "Failed to resolve flag dispute",
        });
    } finally {
        session.endSession();
    }
};

// Remove this helper function as it's no longer needed
// const getActivePiecesFilter = () => {
//     return {
//         $and: [
//             { flag_status: { $ne: 'deleted' } },
//             { live_status: { $ne: false } },
//             { 
//                 $or: [
//                     { flag_status: { $exists: false } },
//                     { flag_status: 'resolved' },
//                     { flag_status: null }
//                 ]
//             }
//         ]
//     };
// };
