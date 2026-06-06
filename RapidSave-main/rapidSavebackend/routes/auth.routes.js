const express         = require('express');
const { body }        = require('express-validator');
const {
  register, login, refreshToken,
  changePassword, forgotPassword, resetPassword,
  verifyEmail, resendVerificationCode, googleSignIn,
} = require('../controllers/auth.controller');
const validate        = require('../middleware/validate.middleware');
const { protect }     = require('../middleware/auth.middleware');
const { authLimiter } = require('../middleware/rateLimiter.middleware');

const router = express.Router();

router.post(
  '/register',
  authLimiter,
  [
    body('name').trim().notEmpty().withMessage('Name is required'),
    body('email').isEmail().withMessage('Valid email is required'),
    body('password').isLength({ min: 6 }).withMessage('Password must be at least 6 characters'),
    body('role').isIn(['patient', 'pharmacy_admin']).withMessage('Invalid role'),
    body('phone').optional().isMobilePhone().withMessage('Invalid phone number'),
  ],
  validate,
  register
);

router.post(
  '/verify-email',
  [
    body('email').isEmail().withMessage('Valid email is required'),
    body('code').trim().notEmpty().withMessage('Verification code is required'),
  ],
  validate,
  verifyEmail
);

router.post(
  '/resend-verification',
  authLimiter,
  [body('email').isEmail().withMessage('Valid email is required')],
  validate,
  resendVerificationCode
);

router.post(
  '/login',
  authLimiter,
  [
    body('email').isEmail().withMessage('Valid email is required'),
    body('password').notEmpty().withMessage('Password is required'),
  ],
  validate,
  login
);

router.post('/refresh', refreshToken);

router.post(
  '/google',
  authLimiter,
  [body('id_token').notEmpty().withMessage('ID token is required')],
  validate,
  googleSignIn
);

router.post(
  '/change-password',
  protect,
  [
    body('current_password').notEmpty().withMessage('Current password is required'),
    body('new_password').isLength({ min: 6 }).withMessage('New password must be at least 6 characters'),
  ],
  validate,
  changePassword
);

router.post(
  '/forgot-password',
  authLimiter,
  [body('email').isEmail().withMessage('Valid email is required')],
  validate,
  forgotPassword
);

router.post(
  '/reset-password',
  [
    body('token').notEmpty().withMessage('Reset token is required'),
    body('new_password').isLength({ min: 6 }).withMessage('Password must be at least 6 characters'),
  ],
  validate,
  resetPassword
);

module.exports = router;