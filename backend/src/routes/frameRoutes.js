const express = require('express');
const router = express.Router();
const frameController = require('../controllers/frameController');
const validateApiKey = require('../middleware/apiKeyMiddleware');
const { validateToken } = require('../middleware/authMiddleware');

// Apply API key validation to all routes
router.use(validateApiKey);

// Public route
router.get('/frames', frameController.getAllFrames);

// Protected routes (require authentication)
router.post('/new_frame', validateToken, frameController.createFrame);
router.put('/frames/:frameId', validateToken, frameController.updateFrame);
router.delete('/frames/:frameId', validateToken, frameController.deleteFrame);

module.exports = router;
