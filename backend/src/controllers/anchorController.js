const Anchor = require('../models/anchors');
const Piece = require('../models/pieces');
const user_profile = require('../models/user_profile');
const mongoose = require('mongoose');

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
            existingAnchorId: existingAnchor.anchorId
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
            message: 'Piece not found'
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
            hasAnchor: !!pieceAnchor,
            anchorId: pieceAnchor ? pieceAnchor.anchorId : null
          });
        }
  
        // Create and save the new anchor
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
          cloudAnchorId
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
          anchorId: newAnchor.anchorId,
          pieceStatus: updatedPiece.live_status,
          userLivePieces: updatedUserProfile.Live_pieces
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
        error: lastError.message
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
