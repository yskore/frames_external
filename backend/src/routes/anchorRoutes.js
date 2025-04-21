const express = require('express');
const router = express.Router();
const anchorController = require('../controllers/anchorController');
const validateApiKey = require('../middleware/apiKeyMiddleware');
const { validateToken, validateTokenOptional} = require('../middleware/authMiddleware');

// Apply API key validation to all routes
router.use(validateApiKey);

// Protected routes (require authentication)
router.post('/anchor', validateToken, anchorController.createAnchor);
router.post('/extend-anchor/:anchorId', validateToken, anchorController.extendAnchorExpiry);
router.post('/extend-expiring-anchors', validateToken, anchorController.extendExpiringAnchors);

// Public routes
router.post('/fetchanchors', anchorController.fetchNearbyAnchors);
router.post('/get_anchors_by_owner', validateTokenOptional, anchorController.getAnchorsByOwner);
router.post('/get_anchor_by_piece_id', anchorController.getAnchorByPieceId);

module.exports = router;
