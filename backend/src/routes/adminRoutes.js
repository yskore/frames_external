const express = require('express');
const router = express.Router();
const adminController = require('../controllers/adminController');
const { validateToken, validateAdminRole } = require('../middleware/authMiddleware');
const { validateAdminDispute } = require('../middleware/validationMiddleware');
const validateApiKey = require('../middleware/apiKeyMiddleware');

// Apply API key validation to all routes
router.use(validateApiKey);

// Admin routes require authentication
router.get('/admin/disputed-offers', validateToken, adminController.getDisputedOffers);
router.post('/admin/resolve-dispute/:offerId', validateToken, adminController.resolveDispute);

// Flag dispute routes
router.get('/admin/flag-disputes', validateToken, adminController.getFlagDisputes);
router.post('/admin/resolve-flag-dispute/:disputeId', validateToken, validateAdminDispute, adminController.resolveFlagDispute);

module.exports = router;
