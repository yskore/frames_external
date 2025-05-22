const Offer = require("../models/offer");
const Piece = require("../models/pieces");
const OwnershipHistory = require("../models/ownership_history");
const user_profile = require("../models/user_profile");
const mongoose = require("mongoose");

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
