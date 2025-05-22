const express = require('express');
const router = express.Router();
const notificationSettingsController = require('../controllers/notificationSettingsController');
const validateApiKey = require('../middleware/apiKeyMiddleware');
const { validateToken } = require('../middleware/authMiddleware');

// Apply API key validation to all routes
router.use(validateApiKey);

router.get('/notification-settings', validateToken, notificationSettingsController.getNotificationSettings);
router.put('/notification-settings', validateToken, notificationSettingsController.updateNotificationSettings);
router.post('/notification-settings/toggle-all', validateToken, notificationSettingsController.toggleAllNotifications);

module.exports = router;
