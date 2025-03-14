const express = require('express');
const router = express.Router();
const profileController = require('../controllers/profileController');
const validateApiKey = require('../middleware/apiKeyMiddleware');
const { validateToken } = require('../middleware/authMiddleware');

// Apply API key validation to all routes
router.use(validateApiKey);

// Protected profile management routes (require authentication)
router.post('/set_profile', profileController.setProfile);
router.post('/update_profile', validateToken, profileController.updateProfile);

// Public profile routes
router.post('/getfollowercount', profileController.getFollowerCount);
router.post('/getfollowingcount', profileController.getFollowingCount);
router.post('/getPieceCount', profileController.getPieceCount);
router.post('/getpiecesbyowner', profileController.getPiecesByOwner);
router.post('/getProfile', profileController.getProfile);

module.exports = router;