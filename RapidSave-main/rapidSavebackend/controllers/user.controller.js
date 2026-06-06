const User        = require('../models/User');
const DeviceToken = require('../models/DeviceToken');
const ApiError    = require('../utils/apiError');
const { sendResponse } = require('../utils/apiResponse');

const getProfile = async (req, res, next) => {
  try {
    sendResponse(res, 200, 'Profile retrieved', req.user);
  } catch (err) {
    next(err);
  }
};

const updateProfile = async (req, res, next) => {
  try {
    const { name, phone } = req.body;
    const user = await User.findByIdAndUpdate(
      req.user._id,
      { name, phone },
      { new: true, runValidators: true }
    ).select('-password_hash');

    sendResponse(res, 200, 'Profile updated', user);
  } catch (err) {
    next(err);
  }
};

const registerDeviceToken = async (req, res, next) => {
  try {
    const { fcm_token, platform } = req.body;

    await DeviceToken.findOneAndUpdate(
      { fcm_token },
      { user_id: req.user._id, fcm_token, platform, is_active: true },
      { upsert: true, new: true }
    );

    sendResponse(res, 200, 'Device token registered');
  } catch (err) {
    next(err);
  }
};

const removeDeviceToken = async (req, res, next) => {
  try {
    await DeviceToken.findOneAndUpdate(
      { fcm_token: req.params.token, user_id: req.user._id },
      { is_active: false }
    );
    sendResponse(res, 200, 'Device token removed');
  } catch (err) {
    next(err);
  }
};

// Diagnostic: check if device tokens are registered for current user
const getMyTokens = async (req, res, next) => {
  try {
    const tokens = await DeviceToken.find({ user_id: req.user._id });
    sendResponse(res, 200, 'Tokens', {
      count:  tokens.length,
      active: tokens.filter(t => t.is_active).length,
      tokens: tokens.map(t => ({
        platform:  t.platform,
        is_active: t.is_active,
        token:     t.fcm_token.substring(0, 20) + '...',
        createdAt: t.createdAt,
      })),
    });
  } catch (err) {
    next(err);
  }
};

module.exports = { getProfile, updateProfile, registerDeviceToken, removeDeviceToken, getMyTokens };