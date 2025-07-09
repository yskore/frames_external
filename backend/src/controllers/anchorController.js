const Anchor = require('../models/anchors');
const Piece = require('../models/pieces');
const user_profile = require('../models/user_profile');
const mongoose = require('mongoose');
const { GoogleAuth } = require('google-auth-library');
const axios = require('axios');
const path = require('path');
const config = require('../config');

// Cloud Anchor Service functionality
const env = process.env.NODE_ENV || 'development';
const arcoreConfig = config.arcore;

// Cloud Anchor Service functionality
const cloudAnchorService = {
    async getAccessToken() {
        try {
            const credentialsPath = path.join(process.cwd(), arcoreConfig.credentials_path);
            console.log(`Looking for credentials at: ${credentialsPath}`);
            
            const auth = new GoogleAuth({
                keyFile: credentialsPath,
                scopes: [arcoreConfig.scope]
            });
            
            const client = await auth.getClient();
            const token = await client.getAccessToken();
            return token.token;
        } catch (error) {
            console.error('Error getting access token:', error);
            throw error;
        }
    },

    async getAnchorDetails(cloudAnchorId) {
        try {
            const token = await this.getAccessToken();
            const response = await axios.get(
                `${arcoreConfig.api_url}/anchors/${cloudAnchorId}`,
                {
                    headers: {
                        'Authorization': `Bearer ${token}`
                    }
                }
            );
            return response.data;
        } catch (error) {
            console.error(`Error getting anchor details for ${cloudAnchorId}:`, error.response?.data || error.message);
            throw error;
        }
    },

    async extendAnchorToMaximum(cloudAnchorId) {
        try {
            // Get current anchor details to obtain the maximumExpireTime
            const anchorDetails = await this.getAnchorDetails(cloudAnchorId);
            const maximumExpireTime = anchorDetails.maximumExpireTime;
            
            if (!maximumExpireTime) {
                throw new Error(`No maximumExpireTime found for anchor ${cloudAnchorId}`);
            }

            // Update the anchor to use the maximum expiry time
            const token = await this.getAccessToken();
            const response = await axios.patch(
                `${arcoreConfig.api_url}/anchors/${cloudAnchorId}?updateMask=expire_time`,
                { expireTime: maximumExpireTime },
                {
                    headers: {
                        'Authorization': `Bearer ${token}`,
                        'Content-Type': 'application/json'
                    }
                }
            );

            return response.data;
        } catch (error) {
            console.error(`Error extending lifetime for anchor ${cloudAnchorId}:`, error.response?.data || error.message);
            throw error;
        }
    }
};

exports.createAnchor = async (req, res) => {
    // Extract client request ID for tracking
    const clientId = req.headers['x-client-id'] || 'unknown';
    console.log(`[${clientId}] Starting anchor operation`);

    let retryAttempts = 5; // Increase retry attempts
    let delay = 500; // Start with lower initial delay
    let lastError = null;

    while (retryAttempts > 0) {
        const session = await mongoose.startSession();

        try {
            console.log(`[${clientId}] Attempt ${6 - retryAttempts}: Starting transaction`);

            // Wait before starting new transaction attempt (not on first attempt)
            if (retryAttempts < 5) {
                console.log(`[${clientId}] Waiting ${delay}ms before retry`);
                await new Promise(resolve => setTimeout(resolve, delay));
            }

            // Use more optimistic transaction settings
            session.startTransaction({
                readConcern: { level: 'local' }, // Less strict for better performance
                writeConcern: { w: 'majority' }
            });

            const {
                anchorId,
                pieceId,
                piece_owner,
                frameName,
                faceName,
                imageUrl,
                latitude,
                longitude,
                arPosition,
                arRotation,
                localScale,
                heightAboveCamera,
                cloudAnchorId
            } = req.body;

            // First check if this anchor already exists
            const existingAnchor = await Anchor.findOne({
                pieceId: pieceId
            }).session(session);

            if (existingAnchor) {
                console.log(`[${clientId}] Anchor already exists for piece ${pieceId}`);
                await session.abortTransaction();
                return res.status(409).json({
                    success: false,
                    message: 'Anchor already exists for this piece',
                    data: {
                        existingAnchorId: existingAnchor.anchorId
                    }
                });
            }

            // Check if piece exists and is not already live
            const existingPiece = await Piece.findOne({
                Piece_id: pieceId
            }).session(session);

            if (!existingPiece) {
                console.log(`[${clientId}] Piece ${pieceId} not found`);
                await session.abortTransaction();
                return res.status(404).json({
                    success: false,
                    message: 'Piece not found',
                    data: null
                });
            }

            // Check if piece is flagged and cannot be made live
            if (existingPiece.flag_status && existingPiece.flag_status !== 'normal' && existingPiece.flag_status !== 'resolved') {
                console.log(`[${clientId}] Piece ${pieceId} is flagged and cannot be made live. Flag status: ${existingPiece.flag_status}`);
                await session.abortTransaction();
                return res.status(403).json({
                    success: false,
                    message: 'This piece cannot be made live due to content moderation restrictions',
                    data: {
                        flagStatus: existingPiece.flag_status,
                        flagType: existingPiece.flag_type
                    }
                });
            }

            if (existingPiece.live_status) {
                console.log(`[${clientId}] Piece ${pieceId} is already live`);

                // Find if there's an anchor for this piece
                const pieceAnchor = await Anchor.findOne({ pieceId }).session(session);

                await session.abortTransaction();
                return res.status(409).json({
                    success: false,
                    message: 'Piece is already live',
                    data: {
                        hasAnchor: !!pieceAnchor,
                        anchorId: pieceAnchor ? pieceAnchor.anchorId : null
                    }
                });
            }

            // Extend cloud anchor lifetime if available
            let extendedAnchorData = null;
            if (cloudAnchorId) {
                try {
                    console.log(`[${clientId}] Extending lifetime for cloud anchor ${cloudAnchorId}`);
                    extendedAnchorData = await cloudAnchorService.extendAnchorToMaximum(cloudAnchorId);
                    console.log(`[${clientId}] Successfully extended anchor lifetime to ${extendedAnchorData.expireTime}`);
                } catch (error) {
                    console.error(`[${clientId}] Failed to extend anchor lifetime: ${error.message}`);
                    // Continue with creation even if extension fails
                }
            }

            // Create and save the new anchor with extended expiry time if available
            const newAnchor = new Anchor({
                anchorId,
                pieceId,
                pieceOwner: piece_owner,
                frameName,
                faceName,
                imageUrl,
                location: {
                    type: 'Point',
                    coordinates: [longitude, latitude]
                },
                arPosition,
                arRotation,
                localScale,
                heightAboveCamera,
                cloudAnchorId,
                expireTime: extendedAnchorData ? new Date(extendedAnchorData.expireTime) : null
            });

            console.log(`[${clientId}] Saving new anchor`);
            await newAnchor.save({ session });

            // Update the piece's live status
            console.log(`[${clientId}] Updating piece live status`);
            const updatedPiece = await Piece.findOneAndUpdate(
                { Piece_id: pieceId },
                { $set: { live_status: true } },
                { session, new: true }
            );

            // Update user profile in one operation
            console.log(`[${clientId}] Updating user profile`);
            const updatedUserProfile = await user_profile.findOneAndUpdate(
                { username: piece_owner },
                { $inc: { Live_pieces: 1 } },
                { session, new: true, runValidators: true }
            );

            if (!updatedUserProfile) {
                throw new Error(`User profile for ${piece_owner} not found`);
            }

            console.log(`[${clientId}] Committing transaction`);
            await session.commitTransaction();
            console.log(`[${clientId}] Transaction committed successfully`);

            return res.status(201).json({
                success: true,
                message: 'Anchor created and related documents updated successfully',
                data: {
                    anchorId: newAnchor.anchorId,
                    pieceStatus: updatedPiece.live_status,
                    userLivePieces: updatedUserProfile.Live_pieces,
                    expireTime: extendedAnchorData ? extendedAnchorData.expireTime : null
                }
            });

        } catch (error) {
            lastError = error;
            console.error(`[${clientId}] Transaction error:`, error.message);

            if (session.inTransaction()) {
                console.log(`[${clientId}] Aborting transaction`);
                await session.abortTransaction();
            }

            // If it's a write conflict and we have retries left
            if ((error.message.includes('Write conflict') ||
                error.code === 112 || // Write conflict code
                error.code === 251) && // Transaction abort code
                retryAttempts > 1) {
                retryAttempts--;
                delay *= 1.5; // Less aggressive backoff
                console.log(`[${clientId}] Write conflict occurred. Retrying in ${delay}ms... (${retryAttempts} attempts left)`);
                continue;
            }

            // If we're out of retries or it's not a write conflict
            retryAttempts = 0; // Force exit from loop
        } finally {
            await session.endSession();
        }
    }

    // If we get here with lastError, we've exhausted retries
    if (lastError) {
        console.error(`[${clientId}] Failed after all retry attempts:`, lastError.message);
        return res.status(500).json({
            success: false,
            message: 'Failed to complete anchor operation after multiple attempts',
            data: null,
            error: lastError.message
        });
    }
};

exports.extendAnchorExpiry = async (req, res) => {
    try {
        const { anchorId } = req.params;
        
        const anchor = await Anchor.findOne({ anchorId });
        if (!anchor || !anchor.cloudAnchorId) {
            return res.status(404).json({
                success: false,
                message: 'Anchor not found or has no cloud anchor ID',
                data: null
            });
        }
        
        const extendedAnchor = await cloudAnchorService.extendAnchorToMaximum(anchor.cloudAnchorId);
        const newExpireTime = new Date(extendedAnchor.expireTime);
        
        // Update the anchor in our database
        await Anchor.updateOne(
            { anchorId },
            { $set: { expireTime: newExpireTime } }
        );
        
        res.status(200).json({
            success: true,
            message: 'Anchor extended successfully',
            data: {
                anchorId: anchor.anchorId,
                cloudAnchorId: anchor.cloudAnchorId,
                newExpireTime: extendedAnchor.expireTime
            }
        });
    } catch (error) {
        console.error('Error extending anchor expiry:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to extend anchor expiry',
            data: null,
            error: error.message
        });
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

        res.status(200).json({
            success: true,
            message: 'Nearby anchors retrieved successfully',
            data: { anchors }
        });
    } catch (error) {
        console.error('Error fetching anchors:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch anchors',
            data: null,
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
                message: 'Username is required',
                data: null
            });
        }

        const anchors = await Anchor.find({ pieceOwner: username });
        res.status(200).json({
            success: true,
            message: 'Anchors retrieved successfully',
            data: { anchors }
        });
    } catch (error) {
        console.error('Error fetching anchors:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch anchors',
            data: null,
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
                message: 'Piece ID is required',
                data: null
            });
        }

        const anchor = await Anchor.findOne({ pieceId });
        if (!anchor) {
            return res.status(404).json({
                success: false,
                message: 'No anchor found for this piece',
                data: null
            });
        }

        res.status(200).json({
            success: true,
            message: 'Anchor retrieved successfully',
            data: { anchor }
        });
    } catch (error) {
        console.error('Error fetching anchor:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch anchor',
            data: null,
            error: error.message
        });
    }
};

exports.extendExpiringAnchors = async (req, res) => {
    try {
        // Calculate date threshold (e.g., 7 days from now)
        const daysThreshold = req.body.days || 7;
        const expiryThreshold = new Date();
        expiryThreshold.setDate(expiryThreshold.getDate() + daysThreshold);
        
        // Find anchors that will expire soon
        const expiringAnchors = await Anchor.find({
            cloudAnchorId: { $exists: true, $ne: '' },
            $or: [
                { expireTime: { $lt: expiryThreshold } },
                { expireTime: { $exists: false } }
            ]
        });
        
        const results = {
            total: expiringAnchors.length,
            processed: 0,
            extended: 0,
            failed: 0,
            details: []
        };
        
        // Process each anchor
        for (const anchor of expiringAnchors) {
            try {
                results.processed++;
                const extendedAnchor = await cloudAnchorService.extendAnchorToMaximum(anchor.cloudAnchorId);
                
                await Anchor.updateOne(
                    { _id: anchor._id },
                    { $set: { expireTime: new Date(extendedAnchor.expireTime) } }
                );
                
                results.extended++;
                results.details.push({
                    anchorId: anchor.anchorId,
                    cloudAnchorId: anchor.cloudAnchorId,
                    expireTime: extendedAnchor.expireTime,
                    status: 'extended'
                });
            } catch (error) {
                results.failed++;
                results.details.push({
                    anchorId: anchor.anchorId,
                    cloudAnchorId: anchor.cloudAnchorId,
                    error: error.message,
                    status: 'failed'
                });
            }
        }
        
        res.status(200).json({
            success: true,
            message: `Processed ${results.processed} anchors, extended ${results.extended}, failed ${results.failed}`,
            data: results
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Failed to process expiring anchors',
            data: null,
            error: error.message
        });
    }
};
