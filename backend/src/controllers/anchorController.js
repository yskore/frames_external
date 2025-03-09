const Anchor = require('../models/anchors');
const Piece = require('../models/pieces');
const user_profile = require('../models/user_profile');
const mongoose = require('mongoose');

exports.createAnchor = async (req, res) => {
    let retryAttempts = 3;
    let delay = 1000;

    while (retryAttempts > 0) {
        const session = await mongoose.startSession();
        try {
            await new Promise(resolve => setTimeout(resolve, delay));
            session.startTransaction({
                readConcern: { level: 'snapshot' },
                writeConcern: { w: 'majority' }
            });

            const {
                anchorId, pieceId, piece_owner, frameName, faceName,
                imageUrl, latitude, longitude, arPosition, arRotation,
                localScale, heightAboveCamera
            } = req.body;

            const newAnchor = new Anchor({
                anchorId, pieceId, pieceOwner: piece_owner,
                frameName, faceName, imageUrl,
                location: {
                    type: 'Point',
                    coordinates: [longitude, latitude]
                },
                arPosition, arRotation, localScale, heightAboveCamera
            });
            await newAnchor.save({ session });

            const [updatedPiece, updatedUserProfile] = await Promise.all([
                Piece.findOneAndUpdate(
                    { Piece_id: pieceId },
                    { $set: { live_status: true } },
                    { session, new: true }
                ),
                user_profile.findOneAndUpdate(
                    { username: piece_owner },
                    { $inc: { Live_pieces: 1 } },
                    { session, new: true }
                )
            ]);

            if (!updatedPiece) throw new Error(`Piece with ID ${pieceId} not found`);
            if (!updatedUserProfile) throw new Error(`User profile for ${piece_owner} not found`);

            await session.commitTransaction();
            return res.status(201).json({
                success: true,
                message: 'Anchor created successfully',
                anchorId: newAnchor.anchorId,
                pieceStatus: updatedPiece.live_status,
                userLivePieces: updatedUserProfile.Live_pieces
            });
        } catch (error) {
            if (session.inTransaction()) await session.abortTransaction();
            
            if (error.message.includes('Write conflict') && retryAttempts > 1) {
                retryAttempts--;
                delay *= 2;
                console.log(`Write conflict occurred. Retrying in ${delay}ms... (${retryAttempts} attempts left)`);
                continue;
            }
            
            console.error('Transaction error:', error);
            return res.status(500).json({
                success: false,
                message: 'Failed to complete anchor operation',
                error: error.message
            });
        } finally {
            await session.endSession();
        }
    }
};

exports.fetchNearbyAnchors = async (req, res) => {
    try {
        const { latitude, longitude, radius = 100 } = req.body;

        const anchors = await Anchor.find({
            location: {
                $near: {
                    $geometry: {
                        type: 'Point',
                        coordinates: [longitude, latitude]
                    },
                    $maxDistance: radius
                }
            }
        });

        res.status(200).json({ success: true, anchors });
    } catch (error) {
        console.error('Error fetching anchors:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch anchors',
            error: error.message
        });
    }
};

exports.getAnchorsByOwner = async (req, res) => {
    try {
        const { username } = req.body;
        if (!username) {
            return res.status(400).json({
                success: false,
                message: 'Username is required'
            });
        }

        const anchors = await Anchor.find({ pieceOwner: username });
        res.status(200).json(anchors);
    } catch (error) {
        console.error('Error fetching anchors:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch anchors',
            error: error.message
        });
    }
};

exports.getAnchorByPieceId = async (req, res) => {
    try {
        const { pieceId } = req.body;
        if (!pieceId) {
            return res.status(400).json({
                success: false,
                message: 'Piece ID is required'
            });
        }

        const anchor = await Anchor.findOne({ pieceId });
        if (!anchor) {
            return res.status(404).json({
                success: false,
                message: 'No anchor found for this piece'
            });
        }

        res.status(200).json(anchor);
    } catch (error) {
        console.error('Error fetching anchor:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch anchor',
            error: error.message
        });
    }
};
