const express = require('express');
const router = express.Router();
const adminController = require('../controllers/adminController');
const validateApiKey = require('../middleware/apiKeyMiddleware');
const { validateToken } = require('../middleware/authMiddleware');

// Apply API key validation to all routes
router.use(validateApiKey);

// Admin routes require authentication
router.get('/admin/disputed-offers', validateToken, adminController.getDisputedOffers);
router.post('/admin/resolve-dispute/:offerId', validateToken, adminController.resolveDispute);

module.exports = router;
