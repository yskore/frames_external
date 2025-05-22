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

// Subscription management routes (require authentication)
router.post('/subscribe', validateToken, profileController.subscribeToUser);
router.post('/unsubscribe', validateToken, profileController.unsubscribeFromUser);
router.get('/my-subscribers', validateToken, profileController.getMySubscribers);
router.get('/my-subscriptions', validateToken, profileController.getMySubscriptions);
router.post('/check-subscription', validateToken, profileController.checkSubscriptionStatus);

router.get('/subscribers/:username', profileController.getSubscribersByUsername);

router.get('/profile', validateToken, profileController.getProfile);
router.get('/pieces', validateToken, profileController.getPiecesByOwner);

router.post('/search_users', profileController.searchUsersByUsername);
router.get('/profile_with_pieces/:username', validateToken, profileController.getProfileWithPieces);

module.exports = router;