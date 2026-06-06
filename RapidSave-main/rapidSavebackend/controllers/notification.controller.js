const Notification  = require('../models/Notification');
const ApiError      = require('../utils/apiError');
const { sendResponse } = require('../utils/apiResponse');
const { notify, markAllRead: markAll, getUnreadCount: countUnread } = require('../services/notification.service');

const getMyNotifications = async (req, res, next) => {
  try {
    const { page = 1, limit = 20, type } = req.query;
    const filter = { user_id: req.user._id };
    if (type) filter.type = type;

    const [notifications, total] = await Promise.all([
      Notification.find(filter)
        .skip((page - 1) * limit)
        .limit(parseInt(limit))
        .sort({ createdAt: -1 }),
      Notification.countDocuments(filter),
    ]);

    sendResponse(res, 200, 'Notifications retrieved', {
      notifications, total, page: parseInt(page), pages: Math.ceil(total / limit),
    });
  } catch (err) {
    next(err);
  }
};

const getUnreadCount = async (req, res, next) => {
  try {
    const count = await countUnread(req.user._id);
    sendResponse(res, 200, 'Unread count retrieved', { count });
  } catch (err) {
    next(err);
  }
};

const markOneRead = async (req, res, next) => {
  try {
    const notification = await Notification.findOneAndUpdate(
      { _id: req.params.id, user_id: req.user._id },
      { is_read: true },
      { new: true }
    );
    if (!notification) return next(new ApiError(404, 'Notification not found'));
    sendResponse(res, 200, 'Notification marked as read', notification);
  } catch (err) {
    next(err);
  }
};

const markAllRead = async (req, res, next) => {
  try {
    await markAll(req.user._id);
    sendResponse(res, 200, 'All notifications marked as read');
  } catch (err) {
    next(err);
  }
};

const sendTestNotification = async (req, res, next) => {
  try {
    await notify(
      req.user._id,
      'order_update',
      'FCM is working! This is a test notification from RapidSave.',
      { test: 'true' },
    );
    sendResponse(res, 200, 'Test notification sent');
  } catch (err) {
    next(err);
  }
};

module.exports = { getMyNotifications, getUnreadCount, markOneRead, markAllRead, sendTestNotification };