const Piece = require('../models/pieces');
const Anchor = require('../models/anchors');
const user_profile = require('../models/user_profile');
const mongoose = require('mongoose');

// Create new piece
exports.createPiece = async (req, res) => {
    const { Piece_id, Piece_Object, Piece_owner, Piece_title, Frame_name, live_status, 
            Piece_likes, Piece_location, Piece_description, Piece_creation_date, 
            Piece_display, Piece_for_sale, Piece_price } = req.body;

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
            Piece_creation_date, Piece_display, Piece_for_sale, Piece_price
        });

        await newPiece.save();
        res.status(201).json({ 
            success: true, 
            message: 'New piece created successfully.', 
            piece: newPiece 
        });
    } catch (err) {
        console.error('Error creating new piece:', err);
        res.status(500).json({ success: false, message: 'Failed to create new piece.' });
    }
};

// Update piece
exports.updatePiece = async (req, res) => {
    const { piece_owner, old_piece_title, new_piece_title, 
            updated_piece_description, piece_for_sale, piece_price } = req.body;

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

        const piece = await Piece.findOneAndUpdate(
            { Piece_owner: piece_owner, Piece_title: old_piece_title },
            {
                Piece_title: new_piece_title,
                Piece_description: updated_piece_description,
                Piece_for_sale: piece_for_sale,
                Piece_price: piece_price
            },
            { new: true, runValidators: true }
        );

        if (!piece) {
            return res.status(404).json({ success: false, message: 'Piece not found' });
        }

        res.status(200).json({ success: true, message: 'Piece updated successfully', piece });
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
            pieceId: piece.Piece_id
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

            const updatedPiece = await Piece.findOneAndUpdate(
                { Piece_id: piece_id },
                { live_status: false },
                { session, new: true }
            );

            await session.commitTransaction();
            return res.status(200).json({
                success: true,
                message: 'Piece set to inactive, anchor removed, and user profile updated',
                piece: updatedPiece,
                userLivePieces: updatedUserProfile.Live_pieces
            });
        }

        if (live_status === true) {
            const updatedPiece = await Piece.findOneAndUpdate(
                { Piece_id: piece_id },
                { live_status: true },
                { session, new: true }
            );

            await session.commitTransaction();
            return res.status(200).json({
                success: true,
                message: 'Piece set to active',
                piece: updatedPiece
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
