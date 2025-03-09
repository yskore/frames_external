const express = require('express');
const router = express.Router();
const bodyParser = require('body-parser');
const { authenticate } = require('../utils/tokenUtils');
const userController = require('../controllers/userController');
const { validateToken, validateTokenOptional } = require('../middleware/authMiddleware');
const { validateUserCreation } = require('../middleware/validationMiddleware');
const validateApiKey = require('../middleware/apiKeyMiddleware');

// Parse JSON bodies
router.use(bodyParser.json());

// Apply API key validation to all routes
router.use(validateApiKey);

// Route to handle POST requests to add new users with validation
router.post('/user_basic', validateUserCreation, userController.createUser);

// Route to check if user exists
router.post('/user_exists', userController.checkUserExists);

// Route for user login
router.post('/login', userController.loginUser);

// Route to get user info with JWT validation if provided
router.get('/user_info', validateTokenOptional, userController.getUserInfo);

// router.get('/profile', validateToken, userController.getUserProfile);
// router.put('/profile/update', validateToken, userController.updateProfile);
// router.get('/protected', validateToken, userController.protectedRoute);

module.exports = router;
