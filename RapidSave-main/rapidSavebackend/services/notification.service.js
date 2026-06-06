const Notification = require('../models/Notification');
const { sendPush }  = require('./fcm.service');

// ── Title map ──────────────────────────────────────────────────────────────────
const _title = (type) => ({
  order_update:    'Order Update',
  delivery_update: 'Delivery Update',
  stock_alert:     'Stock Alert',
  chat_message:    'New Message',
}[type] ?? 'RapidSave');

/**
 * Create a DB notification and optionally send a push.
 * Never throws — notification failure must not break the caller.
 *
 * @param {ObjectId|string} userId
 * @param {'order_update'|'delivery_update'|'stock_alert'|'chat_message'} type
 * @param {string} body   Human-readable message text
 * @param {object} data   Extra key-value data for the push payload
 */
const notify = async (userId, type, body, data = {}) => {
  try {
    await Notification.create({ user_id: userId, type, title: _title(type), body });
  } catch (err) {
    console.error('[notify] DB error:', err.message);
  }
  try {
    await sendPush(userId, { title: _title(type), body, data });
  } catch (err) {
    console.error('[notify] Push error for user', userId, ':', err.message);
  }
};

/**
 * Mark all notifications as read for a user.
 */
const markAllRead = async (userId) => {
  await Notification.updateMany({ user_id: userId, is_read: false }, { is_read: true });
};

/**
 * Return the unread count for a user.
 */
const getUnreadCount = async (userId) => {
  return Notification.countDocuments({ user_id: userId, is_read: false });
};

module.exports = { notify, markAllRead, getUnreadCount };
