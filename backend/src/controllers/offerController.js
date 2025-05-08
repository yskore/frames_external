const Piece = require('../models/pieces');
const Offer = require('../models/offer');
const mongoose = require('mongoose');
const OwnershipHistory = require('../models/ownership_history');
const config = require('../config');
const { sendNotification } = require('../utils/notificationUtils');

exports.declineOffer = async (req, res) => {
    try {
        const { offerId } = req.params;
        const seller = req.user.username;

        const offer = await Offer.findOne({
            _id: offerId,
            seller: seller,
            status: 'pending'
        });

        if (!offer) {
            return res.status(404).json({
                success: false,
                message: 'Offer not found or not in pending status'
            });
        }

        offer.status = 'rejected';
        offer.updated_at = new Date();
        await offer.save();

        // Send notification to buyer about offer rejection
        sendNotification({
            userId: offer.buyer,
            notificationType: 'offer_declined',
            data: {
                id: offer._id.toString(),
                pieceId: offer.piece_id,
                pieceTitle: offer.piece_title || 'Untitled',
                amount: offer.amount,
                sellerUsername: seller,
                date: new Date().toISOString(),
                status: 'rejected'
            }
        }).catch(err => console.error('Error sending notification:', err));

        res.status(200).json({
            success: true,
            message: 'Offer declined successfully',
            data: { offer }
        });

    } catch (error) {
        console.error('Error declining offer:', error);
        res.status(500).json({
            success: false,
            message: error.message || 'Failed to decline offer'
        });
    }
};

exports.cancelOffer = async (req, res) => {
    try {
        const { offerId } = req.params;
        const username = req.user.username;

        // Find the offer
        const offer = await Offer.findById(offerId);
        
        if (!offer) {
            return res.status(404).json({
                success: false,
                message: 'Offer not found'
            });
        }

        // Check if user is the buyer or seller
        const isBuyer = offer.buyer === username;
        const isSeller = offer.seller === username;
        
        if (!isBuyer && !isSeller) {
            return res.status(403).json({
                success: false,
                message: 'Not authorized to cancel this offer'
            });
        }

        // Apply business rules:
        // - Sellers can only cancel if offer is pending
        // - Buyers can cancel if offer is pending or accepted
        if (isSeller && offer.status !== 'pending') {
            return res.status(400).json({
                success: false,
                message: 'Sellers can only cancel pending offers'
            });
        }
        
        if (isBuyer && !['pending', 'accepted'].includes(offer.status)) {
            return res.status(400).json({
                success: false,
                message: 'Buyers can only cancel pending or accepted offers'
            });
        }

        offer.status = 'cancelled';
        offer.updated_at = new Date();
        await offer.save();

        // Determine who cancelled the offer for notification
        const cancelledBy = isBuyer ? 'buyer' : 'seller';
        const recipientId = isBuyer ? offer.seller : offer.buyer;
        
        // Send notification about offer cancellation
        sendNotification({
            userId: recipientId,
            notificationType: 'offer_cancelled',
            data: {
                id: offer._id.toString(),
                pieceId: offer.piece_id,
                pieceTitle: offer.piece_title || 'Untitled',
                amount: offer.amount,
                cancelledBy: cancelledBy,
                username: username,
                date: new Date().toISOString(),
                status: 'cancelled'
            }
        }).catch(err => console.error('Error sending notification:', err));

        res.status(200).json({
            success: true,
            message: 'Offer cancelled successfully',
            data: { offer }
        });

    } catch (error) {
        console.error('Error cancelling offer:', error);
        res.status(500).json({
            success: false,
            message: error.message || 'Failed to cancel offer'
        });
    }
};

// Update the createOffer function to include piece_title
exports.createOffer = async (req, res) => {
    const session = await mongoose.startSession();
    session.startTransaction();

    try {
        const { piece_id } = req.body;
        const buyer = req.user.username;

        // Find the piece and verify it's for sale
        const piece = await Piece.findOne({ 
            Piece_id: piece_id,
            Piece_for_sale: true
        }).session(session);

        if (!piece) {
            throw new Error('Piece not found or not for sale');
        }

        // Prevent self-offers
        if (piece.Piece_owner === buyer) {
            throw new Error('Cannot make an offer on your own piece');
        }

        // Check if piece has accepted offer
        const isPieceAvailable = await Offer.checkPieceAvailability(piece_id);
        if (!isPieceAvailable) {
            throw new Error('This piece already has an accepted offer');
        }

        // Check if buyer already has a pending offer
        const existingOffer = await Offer.findOne({
            piece_id: piece_id,
            buyer: buyer,
            status: 'pending'
        }).session(session);

        if (existingOffer) {
            throw new Error('You already have a pending offer for this piece');
        }

        console.log('Creating new offer for piece:', Piece.Piece_title);

        // Create new offer
        const newOffer = new Offer({
            piece_id: piece_id,
            piece_title: piece.Piece_title || 'Untitled', 
            buyer: buyer,
            payment_details: piece.payment_details,
            currency: piece.currency,
            seller: piece.Piece_owner,
            amount: piece.Piece_price, 
            status: 'pending',
            piece_status: 'available',
            created_at: new Date()
        });

        await newOffer.save({ session });

        // Send notification to seller about new offer
        sendNotification({
            userId: piece.Piece_owner,
            notificationType: 'offer_received',
            data: {
                id: newOffer._id.toString(),
                pieceId: piece_id,
                pieceTitle: piece.Piece_title,
                amount: piece.Piece_price,
                buyerUsername: buyer,
                date: new Date().toISOString(),
                status: 'pending'
            }
        }).catch(err => console.error('Error sending notification:', err));

        await session.commitTransaction();

        res.status(201).json({
            success: true,
            message: 'Offer created successfully',
            data: { offer: newOffer }
        });

    } catch (error) {
        if (session.inTransaction()) {
            await session.abortTransaction();
        }
        console.error('Error creating offer:', error);
        res.status(500).json({
            success: false,
            message: error.message || 'Failed to create offer'
        });
    } finally {
        session.endSession();
    }
};

exports.getPieceOffers = async (req, res) => {
    try {
        const { piece_id } = req.params;
        const username = req.user.username;

        // Verify piece ownership
        const piece = await Piece.findOne({ 
            Piece_id: piece_id,
            Piece_owner: username
        });

        if (!piece) {
            return res.status(403).json({
                success: false,
                message: 'Not authorized to view offers for this piece'
            });
        }

        const offers = await Offer.find({ 
            piece_id: piece_id 
        }).sort({ created_at: -1 });

        res.status(200).json({
            success: true,
            data: { offers }
        });

    } catch (error) {
        console.error('Error fetching piece offers:', error);
        res.status(500).json({
            success: false,
            message: error.message || 'Failed to fetch offers'
        });
    }
};

exports.getReceivedOffers = async (req, res) => {
    try {
        const username = req.user.username;

        const offers = await Offer.find({ 
            seller: username 
        }).sort({ created_at: -1 });

        // Group offers by piece
        const offersByPiece = {};
        offers.forEach(offer => {
            if (!offersByPiece[offer.piece_id]) {
                offersByPiece[offer.piece_id] = [];
            }
            offersByPiece[offer.piece_id].push(offer);
        });

        res.status(200).json({
            success: true,
            data: { 
                offers: offersByPiece
            }
        });

    } catch (error) {
        console.error('Error fetching received offers:', error);
        res.status(500).json({
            success: false,
            message: error.message || 'Failed to fetch received offers'
        });
    }
};

exports.acceptOffer = async (req, res) => {
    const session = await mongoose.startSession();
    session.startTransaction();

    try {
        const { offerId } = req.params;
        const seller = req.user.username;

        const offer = await Offer.findOne({ 
            _id: offerId,
            seller: seller,
            status: 'pending'
        }).session(session);

        if (!offer) {
            throw new Error('Offer not found or not available');
        }

        // Get piece details for notification
        const piece = await Piece.findOne({ Piece_id: offer.piece_id }).session(session);
        
        // Update offer status and set expiration
        const expirationTime = new Date(Date.now() + config.payment.timeout);
        
        const updatedOffer = await Offer.findOneAndUpdate(
            { _id: offerId },
            { 
                status: 'accepted',
                payment_deadline: expirationTime,
                updated_at: new Date()
            },
            { session, new: true }
        );

        // Cancel other pending offers for this piece
        await Offer.updateMany(
            { 
                piece_id: offer.piece_id,
                _id: { $ne: offerId },
                status: 'pending'
            },
            { 
                status: 'cancelled',
                updated_at: new Date()
            },
            { session }
        );

        // Send notification to buyer about offer acceptance
        sendNotification({
            userId: offer.buyer,
            notificationType: 'offer_accepted',
            data: {
                id: offer._id.toString(),
                pieceId: offer.piece_id,
                pieceTitle: piece ? piece.Piece_title : 'Untitled',
                amount: offer.amount,
                sellerUsername: seller,
                date: new Date().toISOString(),
                status: 'accepted',
                deadline: expirationTime.toISOString(),
                timeWindow: '30 minutes'
            },
            priority: 'high'
        }).catch(err => console.error('Error sending notification:', err));

        await session.commitTransaction();

        res.status(200).json({
            success: true,
            message: 'Offer accepted successfully',
            data: { 
                offer: updatedOffer,
                payment_deadline: expirationTime
            }
        });

    } catch (error) {
        if (session.inTransaction()) {
            await session.abortTransaction();
        }
        console.error('Error accepting offer:', error);
        res.status(500).json({
            success: false,
            message: error.message || 'Failed to accept offer'
        });
    } finally {
        session.endSession();
    }
};

exports.submitPaymentProof = async (req, res) => {
    const session = await mongoose.startSession();
    session.startTransaction();
//TODO:delete image from storage if payment proof is denied
    try {
        const { offerId } = req.params;
        const buyer = req.user.username;
        
        // Check if the URL is coming from the uploaded file or from the request body
        let payment_proof_url = req.uploadedFileUrl;
        
        // If no uploaded file URL is found, check if the URL is in the request body (from previous middleware)
        if (!payment_proof_url && req.body && req.body.imageUrl) {
            payment_proof_url = req.body.imageUrl;
        }

        if (!payment_proof_url) {
            throw new Error('Payment proof upload failed: No image URL provided');
        }

        const existingOffer = await Offer.findOne({
            _id: offerId,
            buyer: buyer,
            status: 'accepted'
        }).session(session);

        if (!existingOffer) {
            throw new Error('Offer not found, not in accepted status, or you are not the buyer');
        }

        const now = new Date();
        const seller_confirmation_deadline = new Date(now.getTime() + config.payment.seller_confirmation_timeout);

        // Get piece details for notification
        const piece = await Piece.findOne({ Piece_id: existingOffer.piece_id }).session(session);

        const offer = await Offer.findOneAndUpdate(
            {
                _id: offerId,
                buyer: buyer,
                status: 'accepted'
            },
            {
                payment_proof: payment_proof_url,
                status: 'payment_submitted',
                payment_submitted_at: now,
                seller_confirmation_deadline,
                updated_at: now
            },
            { session, new: true }
        );

        if (!offer) {
            throw new Error('Offer update failed');
        }

        // Send notification to seller about payment submission
        sendNotification({
            userId: offer.seller,
            notificationType: 'payment_submitted',
            data: {
                id: offer._id.toString(),
                pieceId: offer.piece_id,
                pieceTitle: piece ? piece.Piece_title : 'Untitled',
                amount: offer.amount,
                buyerUsername: buyer,
                date: now.toISOString(),
                status: 'payment_submitted',
                deadline: seller_confirmation_deadline.toISOString(),
                paymentProofUrl: payment_proof_url
            },
            priority: 'high'
        }).catch(err => console.error('Error sending notification:', err));

        await session.commitTransaction();
        res.status(200).json({
            success: true,
            message: 'Payment proof submitted successfully',
            data: { 
                offer,
                seller_confirmation_deadline 
            }
        });

    } catch (error) {
        if (session.inTransaction()) {
            await session.abortTransaction();
        }
        console.error('Error submitting payment proof:', error);
        res.status(500).json({
            success: false,
            message: error.message || 'Failed to submit payment proof'
        });
    } finally {
        session.endSession();
    }
};

exports.getPaymentProof = async (req, res) => {
    try {
        const { offerId } = req.params;
        const username = req.user.username;

        const offer = await Offer.findOne({
            _id: offerId,
            status: { $in: ['payment_submitted', 'completed'] },
            $or: [
                { seller: username },
                { buyer: username }
            ]
        });

        if (!offer) {
            return res.status(404).json({
                success: false,
                message: 'No payment proof found or unauthorized to view'
            });
        }

        if (!offer.payment_proof) {
            return res.status(404).json({
                success: false,
                message: 'Payment proof not yet submitted'
            });
        }

        res.status(200).json({
            success: true,
            data: {
                payment_proof_url: offer.payment_proof,
                submitted_at: offer.updated_at,
                status: offer.status
            }
        });

    } catch (error) {
        console.error('Error fetching payment proof:', error);
        res.status(500).json({
            success: false,
            message: error.message || 'Failed to fetch payment proof'
        });
    }
};


exports.handleExpiredConfirmations = async () => {
    const session = await mongoose.startSession();
    session.startTransaction();

    try {
        const { expiredFirstWindow, expiredSecondWindow } = await Offer.checkExpiredConfirmations();

        // Handle first window expiration - move to platform hold
        for (const offer of expiredFirstWindow) {
            const now = new Date();
            const seller_grace_deadline = new Date(now.getTime() + config.payment.seller_grace_timeout);

            const piece = await Piece.findOne({ Piece_id: offer.piece_id }).session(session);
            
            // Update piece_title if it's missing
            if (!offer.piece_title && piece) {
                offer.piece_title = piece.Piece_title || 'Untitled';
            }
            
            await Piece.findOneAndUpdate(
                { Piece_id: offer.piece_id },
                { 
                    temporary_status: 'platform_hold',
                    pending_owner: offer.buyer
                },
                { session }
            );

            offer.seller_grace_deadline = seller_grace_deadline;
            await offer.save({ session });
        }

        // Handle second window expiration - transfer to buyer
        for (const offer of expiredSecondWindow) {
            // Create ownership history record
            const ownershipRecord = new OwnershipHistory({
                piece_id: offer.piece_id,
                owner: offer.buyer,
                transfer_type: 'platform_transfer',
                previous_owner: offer.seller,
                related_offer: offer._id,
                transfer_price: offer.amount,
                start_date: new Date()
            });
            await ownershipRecord.save({ session });

            // Update previous owner's end date
            await OwnershipHistory.findOneAndUpdate(
                { 
                    piece_id: offer.piece_id,
                    owner: offer.seller,
                    end_date: null
                },
                { end_date: new Date() },
                { session }
            );

            // Transfer ownership
            await Piece.findOneAndUpdate(
                { Piece_id: offer.piece_id },
                { 
                    Piece_owner: offer.buyer,
                    temporary_status: 'normal',
                    pending_owner: null,
                    Piece_for_sale: false
                },
                { session }
            );

            offer.status = 'completed';
            await offer.save({ session });
        }

        await session.commitTransaction();
        return { success: true };

    } catch (error) {
        if (session.inTransaction()) {
            await session.abortTransaction();
        }
        console.error('Error handling expired confirmations:', error);
        return { success: false, error: error.message };
    } finally {
        session.endSession();
    }
};

exports.confirmPayment = async (req, res) => {
    const session = await mongoose.startSession();
    session.startTransaction();

    try {
        const { offerId } = req.params;
        const seller = req.user.username;

        const offer = await Offer.findOne({
            _id: offerId,
            seller: seller,
            status: 'payment_submitted'
        }).session(session);

        if (!offer) {
            throw new Error('Offer not found or not in correct state');
        }

        // Get piece details for notification
        const piece = await Piece.findOne({ Piece_id: offer.piece_id }).session(session);
        
        // Update piece_title if it's missing
        if (!offer.piece_title && piece) {
            offer.piece_title = piece.Piece_title || 'Untitled';
            await offer.save({ session });
        }

        // Create new ownership history record and update piece ownership
        const ownershipRecord = new OwnershipHistory({
            piece_id: offer.piece_id,
            owner: offer.buyer,
            transfer_type: 'marketplace_sale',
            previous_owner: offer.seller,
            related_offer: offer._id,
            transfer_price: offer.amount,
            start_date: new Date()
        });
        await ownershipRecord.save({ session });

        // Find the last active ownership record and mark end date
        await OwnershipHistory.findOneAndUpdate(
            { 
                piece_id: offer.piece_id,
                owner: offer.seller,
                end_date: null,
                _id: { $ne: ownershipRecord._id }
            },
            { end_date: new Date() },
            { session }
        );

        // Transfer ownership
        await Piece.findOneAndUpdate(
            { Piece_id: offer.piece_id },
            { 
                Piece_owner: offer.buyer,
                temporary_status: 'normal',
                pending_owner: null,
                Piece_for_sale: false
            },
            { session }
        );

        offer.status = 'completed';
        await offer.save({ session });

        // Send notification to buyer about payment confirmation
        sendNotification({
            userId: offer.buyer,
            notificationType: 'payment_confirmed',
            data: {
                id: offer._id.toString(),
                pieceId: offer.piece_id,
                pieceTitle: piece ? piece.Piece_title : 'Untitled',
                amount: offer.amount,
                sellerUsername: seller,
                date: new Date().toISOString(),
                status: 'completed'
            }
        }).catch(err => console.error('Error sending notification:', err));

        await session.commitTransaction();
        res.status(200).json({
            success: true,
            message: 'Payment confirmed and ownership transferred',
            data: { offer }
        });

    } catch (error) {
        if (session.inTransaction()) {
            await session.abortTransaction();
        }
        console.error('Error confirming payment:', error);
        res.status(500).json({
            success: false,
            message: error.message || 'Failed to confirm payment'
        });
    } finally {
        session.endSession();
    }
};

exports.denyPayment = async (req, res) => {
    const session = await mongoose.startSession();
    session.startTransaction();

    try {
        const { offerId } = req.params;
        const seller = req.user.username;
        const { reason } = req.body;

        const offer = await Offer.findOne({
            _id: offerId,
            seller: seller,
            status: 'payment_submitted'
        }).session(session);

        if (!offer) {
            throw new Error('Offer not found or not in correct state');
        }

        // Get piece details for notification
        const piece = await Piece.findOne({ Piece_id: offer.piece_id }).session(session);

        // Update offer status and create dispute
        offer.status = 'disputed';
        offer.dispute = {
            opened_by: seller,
            reason: reason,
            opened_at: new Date()
        };
        await offer.save({ session });

        // Reset piece status
        await Piece.findOneAndUpdate(
            { Piece_id: offer.piece_id },
            { 
                temporary_status: 'normal',
                pending_owner: null
            },
            { session }
        );

        // Send notification to buyer about payment denial
        sendNotification({
            userId: offer.buyer,
            notificationType: 'payment_denied',
            data: {
                id: offer._id.toString(),
                pieceId: offer.piece_id,
                pieceTitle: piece ? piece.Piece_title : 'Untitled',
                amount: offer.amount,
                sellerUsername: seller,
                date: new Date().toISOString(),
                status: 'disputed',
                reason: reason
            },
            priority: 'high'
        }).catch(err => console.error('Error sending notification:', err));

        await session.commitTransaction();
        res.status(200).json({
            success: true,
            message: 'Payment denied and dispute opened',
            data: { offer }
        });

    } catch (error) {
        if (session.inTransaction()) {
            await session.abortTransaction();
        }
        console.error('Error denying payment:', error);
        res.status(500).json({
            success: false,
            message: error.message || 'Failed to deny payment'
        });
    } finally {
        session.endSession();
    }
};

exports.getMadeOffers = async (req, res) => {
    try {
        const buyer = req.user.username;

        const offers = await Offer.find({ 
            buyer: buyer 
        }).sort({ created_at: -1 });

        res.status(200).json({
            success: true,
            data: { offers }
        });

    } catch (error) {
        console.error('Error fetching made offers:', error);
        res.status(500).json({
            success: false,
            message: error.message || 'Failed to fetch made offers'
        });
    }
};


exports.sendPaymentReminders = async () => {
    try {
        const now = new Date();
        // Find offers that are accepted but expiring soon (10 minutes left)
        const reminderWindow = new Date(now.getTime() + 10 * 60 * 1000); // 10 minutes from now
        
        const offersNeedingReminders = await Offer.find({
            status: 'accepted',
            payment_deadline: { 
                $gt: now,  
                $lt: reminderWindow 
            }
        });

        console.log(`Found ${offersNeedingReminders.length} offers needing payment reminders`);
        
        for (const offer of offersNeedingReminders) {
            const piece = await Piece.findOne({ Piece_id: offer.piece_id });
            
            sendNotification({
                userId: offer.buyer,
                notificationType: 'payment_reminder',
                data: {
                    id: offer._id.toString(),
                    pieceId: offer.piece_id,
                    pieceTitle: piece ? piece.Piece_title : 'Untitled',
                    amount: offer.amount,
                    deadline: offer.payment_deadline.toISOString(),
                    timeLeft: 'less than 10 minutes'
                },
                priority: 'high'
            }).catch(err => console.error(`Error sending reminder for offer ${offer._id}:`, err));
        }
        
        return { 
            success: true, 
            count: offersNeedingReminders.length 
        };
    } catch (error) {
        console.error('Error sending payment reminders:', error);
        return { 
            success: false, 
            error: error.message 
        };
    }
};

exports.sendConfirmationReminders = async () => {
    try {
        const now = new Date();
        // Find offers where payment was submitted but confirmation deadline is approaching (10 minutes left)
        const reminderWindow = new Date(now.getTime() + 10 * 60 * 1000); // 10 minutes from now
        
        const offersNeedingReminders = await Offer.find({
            status: 'payment_submitted',
            seller_confirmation_deadline: { 
                $gt: now, 
                $lt: reminderWindow 
            },
            seller_grace_deadline: { $exists: false }
        });

        console.log(`Found ${offersNeedingReminders.length} offers needing confirmation reminders`);
        
        for (const offer of offersNeedingReminders) {
            const piece = await Piece.findOne({ Piece_id: offer.piece_id });
            
            sendNotification({
                userId: offer.seller,
                notificationType: 'confirmation_reminder',
                data: {
                    id: offer._id.toString(),
                    pieceId: offer.piece_id,
                    pieceTitle: piece ? piece.Piece_title : 'Untitled',
                    amount: offer.amount,
                    buyerUsername: offer.buyer,
                    deadline: offer.seller_confirmation_deadline.toISOString(),
                    timeLeft: 'less than 10 minutes'
                },
                priority: 'high'
            }).catch(err => console.error(`Error sending reminder for offer ${offer._id}:`, err));
        }
        
        return { 
            success: true, 
            count: offersNeedingReminders.length 
        };
    } catch (error) {
        console.error('Error sending confirmation reminders:', error);
        return { 
            success: false, 
            error: error.message 
        };
    }
};

// Add a migration function to update existing records without piece_title
exports.migrateOfferPieceTitles = async () => {
    try {
        const offersWithoutTitle = await Offer.find({ piece_title: { $exists: false } });
        console.log(`Found ${offersWithoutTitle.length} offers without piece_title`);
        
        let updatedCount = 0;
        
        for (const offer of offersWithoutTitle) {
            const piece = await Piece.findOne({ Piece_id: offer.piece_id });
            if (piece) {
                offer.piece_title = piece.Piece_title || 'Untitled';
                await offer.save();
                updatedCount++;
            } else {
                console.warn(`No piece found for offer ${offer._id} with piece_id ${offer.piece_id}`);
                offer.piece_title = 'Unknown Piece';
                await offer.save();
                updatedCount++;
            }
        }
        
        return {
            success: true,
            processedCount: offersWithoutTitle.length,
            updatedCount
        };
    } catch (error) {
        console.error('Error migrating offer piece titles:', error);
        return {
            success: false,
            error: error.message
        };
    }
};
