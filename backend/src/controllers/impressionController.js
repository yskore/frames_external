const Piece = require('../models/pieces');
const mongoose = require('mongoose');

// Increment impression for a piece

exports.incrementImpressions = async (req, res) => {
    try {
      const { pieceId } = req.body;
  
      if (!pieceId) {
        return res.status(400).json({
          success: false,
          message: 'Piece ID is required',
        });
      }
  
      // Use findOneAndUpdate with $inc to atomically increment the impressions counter
      const updatedPiece = await Piece.findOneAndUpdate(
        { Piece_id: pieceId },
        { $inc: { Piece_impressions: 1 } },
        { new: true }
      );
  
      if (!updatedPiece) {
        return res.status(404).json({
          success: false,
          message: 'Piece not found',
        });
      }
  
      return res.status(200).json({
        success: true,
        impressions: updatedPiece.Piece_impressions,
      });
    } catch (error) {
      console.error('Error incrementing impressions:', error);
      return res.status(500).json({
        success: false,
        message: 'Failed to increment impressions',
        error: error.message,
      });
    }
  };

// Get piece's impression count
exports.getPieceImpressions = async (req, res) => {
  try {
    const { pieceId } = req.params;
    
    // Get the piece's total impression count
    const piece = await Piece.findOne({ Piece_id: pieceId }, { Piece_impressions: 1, Piece_title: 1 });
    
    if (!piece) {
      return res.status(404).json({
        success: false,
        message: 'Piece not found'
      });
    }
    
    res.status(200).json({
      success: true,
      data: {
        pieceId,
        title: piece.Piece_title,
        impressions: piece.Piece_impressions || 0
      }
    });
  } catch (error) {
    console.error('Error fetching piece impressions:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch piece impressions',
      error: error.message
    });
  }
};

// Get total impressions for all pieces owned by a user
exports.getUserTotalImpressions = async (req, res) => {
  try {
    const { username } = req.params;
    
    // Aggregate total impressions across all pieces owned by the user
    const result = await Piece.aggregate([
      { $match: { Piece_owner: username } },
      { $group: {
          _id: null,
          totalImpressions: { $sum: '$Piece_impressions' },
          pieceCount: { $sum: 1 } 
        }
      }
    ]);
    
    // Handle case where user has no pieces
    const totalImpressions = result.length > 0 ? result[0].totalImpressions : 0;
    const pieceCount = result.length > 0 ? result[0].pieceCount : 0;
    
    res.status(200).json({
      success: true,
      data: {
        username,
        totalImpressions,
        pieceCount
      }
    });
  } catch (error) {
    console.error('Error fetching user impression stats:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch user impression stats',
      error: error.message
    });
  }
};

// Optional: Get impression stats for all user's pieces
exports.getUserPieceImpressions = async (req, res) => {
  try {
    const { username } = req.params;
    
    // Find all pieces and sort by impressions
    const pieces = await Piece.find(
      { Piece_owner: username },
      { Piece_id: 1, Piece_title: 1, Piece_impressions: 1, Piece_display: 1 }
    ).sort({ Piece_impressions: -1 });
    
    const pieceStats = pieces.map(piece => ({
      pieceId: piece.Piece_id,
      title: piece.Piece_title,
      impressions: piece.Piece_impressions || 0,
      displayUrl: piece.Piece_display
    }));
    
    res.status(200).json({
      success: true,
      data: {
        username,
        pieceCount: pieces.length,
        totalImpressions: pieces.reduce((total, piece) => total + (piece.Piece_impressions || 0), 0),
        pieces: pieceStats
      }
    });
  } catch (error) {
    console.error('Error fetching user piece impressions:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch user piece impressions',
      error: error.message
    });
  }
};