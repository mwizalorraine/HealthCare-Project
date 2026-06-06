const express = require('express');
const {
  getMyNotifications, markOneRead,
  markAllRead, getUnreadCount, sendTestNotification,
} = require('../controllers/notification.controller');
const { protect } = require('../middleware/auth.middleware');

const router = express.Router();

router.use(protect);

router.get('/',             getMyNotifications);
router.get('/unread-count', getUnreadCount);
router.post('/test',        sendTestNotification);
router.patch('/:id/read',   markOneRead);
router.patch('/read-all',   markAllRead);

module.exports = router;