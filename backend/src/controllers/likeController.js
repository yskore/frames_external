const Like = require('../models/likes');
const Piece = require('../models/pieces');
const mongoose = require('mongoose');

// Toggle like status (like or unlike)
exports.toggleLike = async (req, res) => {
  const session = await mongoose.startSession();
  session.startTransaction();

  try {
    const { pieceId, username } = req.body;

    if (!pieceId || !username) {
      return res.status(400).json({
        success: false,
        message: 'Piece ID and username are required',
      });
    }

    // First, find the piece to make sure it exists
    const piece = await Piece.findOne({ Piece_id: pieceId }).session(session);
    
    if (!piece) {
      await session.abortTransaction();
      return res.status(404).json({
        success: false,
        message: 'Piece not found',
      });
    }

    // Check if user already liked this piece
    const existingLike = await Like.findOne({ username, pieceId }).session(session);

    let isLiked;
    if (existingLike) {
      // User already liked the piece, so unlike it
      await Like.deleteOne({ _id: existingLike._id }).session(session);
      
      // Decrement like count on the piece
      await Piece.updateOne(
        { Piece_id: pieceId },
        { $inc: { Piece_likes: -1 } }
      ).session(session);
      
      isLiked = false;
    } else {
      // User hasn't liked the piece yet, so like it
      const newLike = new Like({ username, pieceId });
      await newLike.save({ session });
      
      // Increment like count on the piece
      await Piece.updateOne(
        { Piece_id: pieceId },
        { $inc: { Piece_likes: 1 } }
      ).session(session);
      
      isLiked = true;
    }

    // Get the updated like count
    const updatedPiece = await Piece.findOne({ Piece_id: pieceId }).session(session);
    
    await session.commitTransaction();
    
    return res.status(200).json({
      success: true,
      message: isLiked ? 'Piece liked successfully' : 'Piece unliked successfully',
      data: {
        isLiked,
        likeCount: updatedPiece.Piece_likes
      }
    });
  } catch (error) {
    await session.abortTransaction();
    console.error('Like toggle error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to toggle like status',
      error: error.message
    });
  } finally {
    session.endSession();
  }
};

// Check if a user has liked a piece
exports.checkLikeStatus = async (req, res) => {
  try {
    const { pieceId, username } = req.query;

    if (!pieceId || !username) {
      return res.status(400).json({
        success: false,
        message: 'Piece ID and username are required',
      });
    }

    const like = await Like.findOne({ username, pieceId });
    const piece = await Piece.findOne({ Piece_id: pieceId }, 'Piece_likes');

    return res.status(200).json({
      success: true,
      data: {
        isLiked: !!like,
        likeCount: piece ? piece.Piece_likes : 0
      }
    });
  } catch (error) {
    console.error('Check like status error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to check like status',
      error: error.message
    });
  }
};

// Get all pieces liked by a user
exports.getUserLikes = async (req, res) => {
  try {
    const { username } = req.params;

    if (!username) {
      return res.status(400).json({
        success: false,
        message: 'Username is required',
      });
    }

    // Find all likes by this user
    const likes = await Like.find({ username });
    
    // Extract piece IDs
    const pieceIds = likes.map(like => like.pieceId);
    
    // Find all pieces corresponding to these likes
    const likedPieces = await Piece.find({ Piece_id: { $in: pieceIds } });

    return res.status(200).json({
      success: true,
      data: {
        likes: likedPieces
      }
    });
  } catch (error) {
    console.error('Get user likes error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to get user likes',
      error: error.message
    });
  }
};

// Get piece's like count and most recent likers
exports.getPieceLikes = async (req, res) => {
  try {
    const { pieceId } = req.params;
    const limit = req.query.limit ? parseInt(req.query.limit) : 5;

    if (!pieceId) {
      return res.status(400).json({
        success: false,
        message: 'Piece ID is required',
      });
    }

    // Find the piece to get total like count
    const piece = await Piece.findOne({ Piece_id: pieceId }, 'Piece_likes');
    
    if (!piece) {
      return res.status(404).json({
        success: false,
        message: 'Piece not found',
      });
    }

    // Get the most recent users who liked this piece
    const recentLikes = await Like.find({ pieceId })
      .sort({ createdAt: -1 })
      .limit(limit);

    return res.status(200).json({
      success: true,
      data: {
        likeCount: piece.Piece_likes,
        recentLikes: recentLikes
      }
    });
  } catch (error) {
    console.error('Get piece likes error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to get piece likes',
      error: error.message
    });
  }
};