const express = require('express');
const router = express.Router();
const impressionController = require('../controllers/impressionController');

// Routes for impression tracking
router.post('/increment_impression', impressionController.incrementImpressions);

// Get piece's impression count
router.get('/piece_impressions/:pieceId', impressionController.getPieceImpressions);

// Get total impressions for all pieces owned by a user
router.get('/user_impressions/:username', impressionController.getUserTotalImpressions);

module.exports = router;