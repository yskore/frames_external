const express = require('express');
const router = express.Router();
const pieceController = require('../controllers/pieceController');
const validateApiKey = require('../middleware/apiKeyMiddleware');
const { validateToken } = require('../middleware/authMiddleware');

// Apply API key validation to all routes
router.use(validateApiKey);

// Piece management routes (all require authentication)
router.post('/new_piece', validateToken, pieceController.createPiece);
router.put('/update_piece', validateToken, pieceController.updatePiece);
router.post('/delete_piece', validateToken, pieceController.deletePiece);
router.post('/toggle_live_status', validateToken, pieceController.toggleLiveStatus);
router.get('/piece/:pieceId', pieceController.getPieceById);


module.exports = router;
