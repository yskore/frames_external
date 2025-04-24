const express = require('express');
const router = express.Router();
const likeController = require('../controllers/likeController');

// Toggle like status (like or unlike)
router.post('/toggle_like', likeController.toggleLike);

// Check if a user has liked a piece
router.get('/check_like', likeController.checkLikeStatus);

// Get all pieces liked by a user
router.get('/user_likes/:username', likeController.getUserLikes);

// Get piece's like count and most recent likers
router.get('/piece_likes/:pieceId', likeController.getPieceLikes);

module.exports = router;
