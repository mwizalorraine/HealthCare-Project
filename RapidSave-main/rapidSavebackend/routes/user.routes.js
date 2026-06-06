const express       = require('express');
const { body }      = require('express-validator');
const {
  getProfile, updateProfile,
  registerDeviceToken, removeDeviceToken, getMyTokens,
} = require('../controllers/user.controller');
const { protect }   = require('../middleware/auth.middleware');
const validate      = require('../middleware/validate.middleware');

const router = express.Router();

router.use(protect);

router.get('/me', getProfile);

router.patch(
  '/me',
  [
    body('name').optional().trim().notEmpty().withMessage('Name cannot be empty'),
    body('phone').optional().isMobilePhone().withMessage('Invalid phone number'),
  ],
  validate,
  updateProfile
);

router.post(
  '/device-token',
  [
    body('fcm_token').notEmpty().withMessage('FCM token is required'),
    body('platform').isIn(['android', 'ios', 'web']).withMessage('Invalid platform'),
  ],
  validate,
  registerDeviceToken
);

router.delete('/device-token/:token', removeDeviceToken);
router.get('/device-tokens', getMyTokens); // diagnostic

module.exports = router;