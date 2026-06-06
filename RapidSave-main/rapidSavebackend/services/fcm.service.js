const admin       = require('firebase-admin');
const DeviceToken = require('../models/DeviceToken');

const sendPush = async (userId, { title, body, data = {} }) => {
  const tokens = await DeviceToken.find({ user_id: userId, is_active: true }).select('fcm_token');
  if (!tokens.length) {
    console.log(`[FCM] No device tokens for user ${userId} — push skipped. User must log in again to register token.`);
    return;
  }
  console.log(`[FCM] Sending "${title}" to ${tokens.length} token(s) for user ${userId}`);

  const registrationTokens = tokens.map((t) => t.fcm_token);

  const message = {
    notification: { title, body },
    data:         Object.fromEntries(Object.entries(data).map(([k, v]) => [k, String(v)])),
    tokens:       registrationTokens,
  };

  const response = await admin.messaging().sendEachForMulticast(message);
  const successCount = response.responses.filter(r => r.success).length;
  console.log(`[FCM] Delivered ${successCount}/${tokens.length} messages`);

  const staleTokens = [];
  response.responses.forEach((res, idx) => {
    if (!res.success && res.error?.code === 'messaging/registration-token-not-registered') {
      staleTokens.push(registrationTokens[idx]);
    }
  });

  if (staleTokens.length) {
    await DeviceToken.updateMany(
      { fcm_token: { $in: staleTokens } },
      { is_active: false }
    );
  }
};

const sendPushToMany = async (userIds, payload) => {
  await Promise.all(userIds.map((id) => sendPush(id, payload)));
};

module.exports = { sendPush, sendPushToMany };