const express = require('express');
const router = express.Router();
const otpController = require('../controllers/otpController');
const validateApiKey = require('../middleware/apiKeyMiddleware');

// Apply API key validation to all routes
router.use(validateApiKey);

// OTP routes
router.post('/send-otp', otpController.sendOTP);
router.post('/verify-otp', otpController.verifyOTP);

module.exports = router;
