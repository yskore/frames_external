const express = require('express');
const router = express.Router();
const storageController = require('../controllers/storageController');
const validateApiKey = require('../middleware/apiKeyMiddleware');
const { validateToken } = require('../middleware/authMiddleware');

// Apply API key validation to all routes
router.use(validateApiKey);

// Protected routes (require authentication)
router.post('/upload-image', validateToken, storageController.uploadImage);
router.post('/delete-image', validateToken, storageController.deleteImage);
router.post('/set-current-image', validateToken, storageController.setCurrentImage);
router.get('/get-current-image', validateToken, storageController.getCurrentImage);

module.exports = router;
