const express = require('express');
const router = express.Router();
const feedController = require('../controllers/feedController');
const validateApiKey = require('../middleware/apiKeyMiddleware');
const { validateToken } = require('../middleware/authMiddleware');

router.use(validateApiKey);


router.get('/feed',validateToken, feedController.getFeed);
router.get('/feed/unread-count',validateToken, feedController.getUnreadCount);
router.post('/feed/mark-read',validateToken, feedController.markAsRead);
router.post('/feed/mark-all-read',validateToken, feedController.markAllAsRead);
router.delete('/feed/:entryId',validateToken, feedController.deleteFeedEntry);

module.exports = router;
