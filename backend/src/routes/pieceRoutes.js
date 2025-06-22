const express = require('express');
const router = express.Router();
const pieceController = require('../controllers/pieceController');
const validateApiKey = require('../middleware/apiKeyMiddleware');
const { validateToken } = require('../middleware/authMiddleware');
const { validatePieceInput, validateSaleToggle } = require('../middleware/pieceValidationMiddleware');

router.use(validateApiKey);

// Add new route for getting owner's pieces
router.get('/my-pieces', validateToken, pieceController.getOwnerPieces);

// Add validation middleware to existing routes
router.post('/new_piece', validateToken, validatePieceInput, pieceController.createPiece);
router.put('/update_piece', validateToken, validatePieceInput, pieceController.updatePiece);
router.post('/delete_piece', validateToken, pieceController.deletePiece);
router.post('/toggle_live_status', validateToken, pieceController.toggleLiveStatus);
router.get('/piece/:pieceId', pieceController.getPieceById);


// Add new route for toggling sale status
router.post('/toggle_for_sale', validateToken, validateSaleToggle, pieceController.toggleForSale);
// new route for getting pieces by Title
router.post('/search_pieces', pieceController.searchPieces);


module.exports = router;
