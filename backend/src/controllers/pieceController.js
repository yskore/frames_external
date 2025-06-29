
const Piece = require('../models/pieces');
const Anchor = require('../models/anchors');
const user_profile = require('../models/user_profile');
const mongoose = require('mongoose');
const { createFeedEntryForSubscribers } = require('./feedController');

// Create new piece
exports.createPiece = async (req, res) => {
    const { Piece_id, Piece_Object, Piece_owner, Piece_title, Frame_name, live_status,
        Piece_likes, Piece_location, Piece_description, Piece_creation_date,
        Piece_display, Piece_for_sale, Piece_price, ownership, 
        isHidden, showRadius } = req.body; // Added isHidden and showRadius

    try {
        const existingPiece = await Piece.findOne({ Piece_owner, Piece_title });
        if (existingPiece) {
            return res.status(400).json({
                success: false,
                message: 'Failed to create piece, a user cannot have pieces with the same name'
            });
        }

        const newPiece = new Piece({
            Piece_id, Piece_Object, Piece_owner, Piece_title, Frame_name,
            live_status, Piece_likes, Piece_location, Piece_description,
            Piece_creation_date, Piece_display, Piece_for_sale, Piece_price,
            ownership: ownership || '00', // Default to '00' if not provided
            isHidden: isHidden || false, // Default to false if not provided
            showRadius: showRadius || 0  // Default to 0 if not provided
        });

        // Add payment details to piece if for sale
        if (Piece_for_sale) {
            const { payment_details } = req.body;
            newPiece.payment_details = payment_details;
        }

        await newPiece.save();
        
        // Create feed entries for subscribers
        await createFeedEntryForSubscribers(
            Piece_owner, 
            'posted_piece',
            newPiece._id.toString(),
            Piece_title,
            { 
                description: Piece_description,
                ownerUsername: Piece_owner,
                pieceImage: Piece_display || ''
            }
        );
        
        res.status(201).json({
            success: true,
            message: 'New piece created successfully',
            data: { piece: newPiece }
        });
    } catch (err) {
        console.error('Error creating new piece:', err);
        res.status(500).json({ success: false, message: 'Failed to create new piece.' });
    }
};

// Update piece
exports.updatePiece = async (req, res) => {
    const { piece_owner, old_piece_title, new_piece_title,
        updated_piece_description, piece_for_sale, piece_price, ownership,
        isHidden, showRadius } = req.body;

    try {
        if (old_piece_title !== new_piece_title) {
            const existingPiece = await Piece.findOne({
                Piece_owner: piece_owner,
                Piece_title: new_piece_title
            });
            if (existingPiece) {
                return res.status(400).json({
                    success: false,
                    message: 'Failed to update piece, a user cannot have pieces with the same name'
                });
            }
        }

        const updateData = {
            Piece_title: new_piece_title,
            Piece_description: updated_piece_description,
            Piece_for_sale: piece_for_sale,
            Piece_price: piece_price
        };

        // Only update ownership if provided
        if (ownership) {
            updateData.ownership = ownership;
        }

        // Handle hidden fields
        if (isHidden !== undefined) {
            updateData.isHidden = isHidden;
        }

        if (showRadius !== undefined) {
            // Validate showRadius
            if (showRadius < 0 || showRadius > 500) {
                return res.status(400).json({
                    success: false,
                    message: 'Show radius must be between 0 and 500 meters'
                });
            }
            updateData.showRadius = showRadius;
        }

        if (piece_for_sale) {
            const { payment_details } = req.body;
            updateData.payment_details = payment_details;
        }

        const piece = await Piece.findOneAndUpdate(
            { Piece_owner: piece_owner, Piece_title: old_piece_title },
            updateData,
            { new: true, runValidators: true }
        );

        if (!piece) {
            return res.status(404).json({ success: false, message: 'Piece not found' });
        }

        res.status(200).json({
            success: true,
            message: 'Piece updated successfully',
            data: { piece }
        });
    } catch (err) {
        console.error('Error updating piece:', err);
        res.status(500).json({ success: false, message: 'Failed to update piece' });
    }
};
// Delete piece
exports.deletePiece = async (req, res) => {
    const { piece_title, piece_owner } = req.body;

    const username = req.user;


    const session = await mongoose.startSession();
    session.startTransaction();

    try {
        const piece = await Piece.findOne({
            Piece_title: piece_title,
            Piece_owner: piece_owner
        }).session(session);

        if (!piece) {
            throw new Error('Piece not found');
        }

        if (piece.live_status) {
            const deleteResult = await Anchor.deleteOne(
                { pieceId: piece.Piece_id },
                { session }
            );

            if (deleteResult.deletedCount) {
                const updatedUserProfile = await user_profile.findOneAndUpdate(
                    { username: piece_owner },
                    { $inc: { Live_pieces: -1 } },
                    { session, new: true }
                );

                if (!updatedUserProfile) {
                    throw new Error(`User profile for ${piece_owner} not found`);
                }
            }
        }

        const deletePieceResult = await Piece.deleteOne(
            { _id: piece._id },
            { session }
        );

        if (!deletePieceResult.deletedCount) {
            throw new Error('Failed to delete piece');
        }

        await session.commitTransaction();
        res.status(200).json({
            success: true,
            message: 'Piece and associated data deleted successfully',
            data: { pieceId: piece.Piece_id }
        });
    } catch (error) {
        if (session.inTransaction()) {
            await session.abortTransaction();
        }
        console.error('Error deleting piece:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to delete piece',
            error: error.message
        });
    } finally {
        session.endSession();
    }
};

// Add new toggle live status function
exports.toggleLiveStatus = async (req, res) => {
    const { piece_id, live_status } = req.body;
    const session = await mongoose.startSession();
    session.startTransaction();

    try {
        const piece = await Piece.findOne({ Piece_id: piece_id }).session(session);

        if (!piece) {
            throw new Error('Piece not found');
        }

        const piece_owner = piece.Piece_owner;

        if (live_status === false) {
            const deleteResult = await Anchor.deleteOne(
                { pieceId: piece_id },
                { session }
            );

            let updatedUserProfile = null;

            if (deleteResult.deletedCount) {
                updatedUserProfile = await user_profile.findOneAndUpdate(
                    { username: piece_owner },
                    { $inc: { Live_pieces: -1 } },
                    { session, new: true }
                );

                if (!updatedUserProfile) {
                    throw new Error(`User profile for ${piece_owner} not found`);
                }
            }

            const updatedPiece = await Piece.findOneAndUpdate(
                { Piece_id: piece_id },
                { live_status: false },
                { session, new: true }
            );

            await session.commitTransaction();
            return res.status(200).json({
                success: true,
                message: 'Piece set to inactive',
                data: {
                    piece: updatedPiece,
                    userLivePieces: updatedUserProfile ? updatedUserProfile.Live_pieces : null
                }
            });
        }

        if (live_status === true) {
            const updatedPiece = await Piece.findOneAndUpdate(
                { Piece_id: piece_id },
                { live_status: true },
                { session, new: true }
            );

            await session.commitTransaction();
            
            // Create feed entries for subscribers when a piece goes live
            await createFeedEntryForSubscribers(
                piece.Piece_owner,
                'made_piece_live',
                piece_id,
                piece.Piece_title,
                { 
                    description: piece.Piece_description,
                    ownerUsername: piece.Piece_owner,
                    pieceImage: piece.Piece_display || ''
                }
            );
            
            return res.status(200).json({
                success: true,
                message: 'Piece set to active',
                data: { piece: updatedPiece }
            });
        }

        throw new Error('Invalid live_status value. Must be true or false.');

    } catch (error) {
        if (session.inTransaction()) {
            await session.abortTransaction();
        }
        console.error('Error toggling live status:', error);
        return res.status(500).json({
            success: false,
            message: 'Failed to toggle piece live status',
            error: error.message
        });
    } finally {
        session.endSession();
    }
};

exports.getOwnerPieces = async (req, res) => {
    try {
        const username = req.user.username;
        const pieces = await Piece.find({ Piece_owner: username });

        res.status(200).json({
            success: true,
            data: { pieces }
        });
    } catch (error) {
        console.error('Error fetching pieces:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch pieces'
        });
    }
};

// Simplified toggleForSale method
exports.toggleForSale = async (req, res) => {
    try {
        const { piece_id, for_sale, price, payment_details } = req.body;
        const username = req.user.username;

        console.log(req.user);
        console.log('Username:', username);
        console.log('Piece ID:', piece_id);

        const piece = await Piece.findOne({
            Piece_id: piece_id,
            Piece_owner: username
        });

        if (!piece) {
            throw new Error('Piece not found or not owned by user');
        }

        const updatedPiece = await Piece.findOneAndUpdate(
            { Piece_id: piece_id },
            {
                Piece_for_sale: for_sale,
                Piece_price: for_sale ? price : 0,
                payment_details: for_sale ? payment_details : null
            },
            { new: true }
        );

        // If the piece is being listed for sale, create feed entries for subscribers
        if (for_sale) {
            await createFeedEntryForSubscribers(
                username,
                'listed_for_sale',
                piece_id,
                piece.Piece_title,
                { 
                    price: price,
                    description: piece.Piece_description,
                    ownerUsername: username,
                    pieceImage: piece.Piece_display || '',
                    currency: 'USD'
                }
            );
        }

        res.status(200).json({
            success: true,
            message: `Piece ${for_sale ? 'listed for sale' : 'unlisted from sale'} successfully`,
            data: { piece: updatedPiece }
        });
    } catch (error) {
        console.error('Error toggling sale status:', error);
        res.status(500).json({
            success: false,
            message: error.message || 'Failed to update piece sale status'
        });
    }
};

// Get piece by ID
exports.getPieceById = async (req, res) => {
    const { pieceId } = req.params;

    try {
        // Find the piece
        const piece = await Piece.findOne({ Piece_id: pieceId });

        if (!piece) {
            return res.status(404).json({
                success: false,
                message: 'Piece not found'
            });
        }

        // Format the response with parsed fields
        const formattedPiece = {
            id: piece.Piece_id,
            title: piece.Piece_title,
            owner: piece.Piece_owner,
            frameName: piece.Frame_name,
            description: piece.Piece_description,
            imageUrl: piece.Piece_display,
            creationDate: piece.Piece_creation_date,
            likes: piece.Piece_likes,
            impressions: piece.Piece_impressions,
            currency: piece.currency,
            payment_details: piece.payment_details,
            ownership: piece.ownership || '00',
            isLive: piece.live_status,
            forSale: piece.Piece_for_sale,
            price: piece.Piece_price,
            isHidden: piece.isHidden || false, // Default to false if not present
            showRadius: piece.showRadius || 0   // Default to 0 if not present
        };

        res.status(200).json({
            success: true,
            message: 'Piece retrieved by ID successfully',
            data: { piece: formattedPiece }
        });
    } catch (error) {
        console.error('Error retrieving piece:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to retrieve piece information',
            error: error.message
        });
    }
};


// Search pieces by title
exports.searchPieces = async (req, res) => {
    try {
        const { query } = req.body;

        if (!query) {
            return res.status(400).json({
                success: false,
                message: 'Search query is required'
            });
        }

        const searchPattern = new RegExp(query, 'i');

        const pieces = await Piece.find(
            { Piece_title: searchPattern },
            { 
                Piece_id: 1, 
                Piece_title: 1, 
                Piece_owner: 1, 
                Frame_name: 1,
                Piece_description: 1,
                Piece_display: 1,
                Piece_creation_date: 1,
                Piece_likes: 1,
                Piece_impressions: 1,
                currency: 1,
                payment_details: 1,
                ownership: 1,
                live_status: 1,
                Piece_for_sale: 1,
                Piece_price: 1,
                isHidden: 1,
                showRadius: 1,
                _id: 0 
            }
        ).limit(20);

        const formattedPieces = pieces.map(piece => ({
            id: piece.Piece_id,
            title: piece.Piece_title,
            owner: piece.Piece_owner,
            frameName: piece.Frame_name,
            description: piece.Piece_description,
            imageUrl: piece.Piece_display,
            creationDate: piece.Piece_creation_date,
            likes: piece.Piece_likes,
            impressions: piece.Piece_impressions,
            currency: piece.currency,
            payment_details: piece.payment_details,
            ownership: piece.ownership || '00',
            isLive: piece.live_status,
            forSale: piece.Piece_for_sale,
            price: piece.Piece_price,
            isHidden: piece.isHidden || false, // Default to false if not present
            showRadius: piece.showRadius || 0   // Default to 0 if not present
        }));

        res.json({
            success: true,
            message: 'Pieces retrieved successfully',
            data: { pieces: formattedPieces }
        });
    } catch (error) {
        console.error('Error in searchPieces:', error);
        res.status(500).json({ success: false, message: 'Internal server error' });
    }
};

