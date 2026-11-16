const express = require('express');
const {
  listNotifications,
  unreadCount,
  markRead,
  markAllRead,
} = require('../controllers/notificationController');
const {
  listNotificationRules,
  notificationIdRules,
} = require('../validators/notificationValidator');
const validate = require('../middleware/validateMiddleware');
const { protect } = require('../middleware/authMiddleware');

const router = express.Router();

router.use(protect);

router.get('/', listNotificationRules, validate, listNotifications);
router.get('/unread-count', unreadCount);
router.patch('/read-all', markAllRead);
router.patch('/:id/read', notificationIdRules, validate, markRead);

module.exports = router;