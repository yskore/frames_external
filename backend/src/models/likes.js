const mongoose = require('mongoose');

// Define schema for likes
const LikeSchema = new mongoose.Schema({
  username: { 
    type: String, 
    required: true 
  },
  pieceId: { 
    type: String, 
    required: true 
  },
  timestamp: { 
    type: Date, 
    default: Date.now 
  }
}, { timestamps: true });

// Create a compound index for username and pieceId
// This ensures uniqueness and optimizes queries
LikeSchema.index({ username: 1, pieceId: 1 }, { unique: true });

// Add additional indexes for common queries
LikeSchema.index({ pieceId: 1 }); // For counting likes per piece
LikeSchema.index({ username: 1 });  // For finding all pieces a user has liked

const Like = mongoose.model('Like', LikeSchema, 'likes');

module.exports = Like;