const crypto        = require('crypto');
const jwt           = require('jsonwebtoken');
const { OAuth2Client } = require('google-auth-library');
const User          = require('../models/User');
const generateToken = require('../utils/generateToken');
const ApiError      = require('../utils/apiError');
const { sendResponse } = require('../utils/apiResponse');
const {
  sendVerificationEmail,
  sendWelcomeEmail,
  sendPasswordResetEmail,
} = require('../services/email.service');

const generateVerificationCode = () =>
  Math.floor(100000 + Math.random() * 900000).toString();

const register = async (req, res, next) => {
  try {
    const { name, email, password, role, phone } = req.body;

    const existing = await User.findOne({ email });

    // If account exists and is already verified — block
    if (existing && existing.email_verified) {
      return next(new ApiError(409, 'Email already registered'));
    }

    const code   = generateVerificationCode();
    const expiry = new Date(Date.now() + 15 * 60 * 1000);

    let user;

    if (existing && !existing.email_verified) {
      // Account exists but not verified — update it and resend code
      existing.name                = name;
      existing.password_hash       = password;
      existing.role                = role;
      existing.phone               = phone;
      existing.verification_code   = code;
      existing.verification_expiry = expiry;
      await existing.save();
      user = existing;
    } else {
      // New account
      user = await User.create({
        name, email, password_hash: password, role, phone,
        verification_code:   code,
        verification_expiry: expiry,
        email_verified:      false,
      });
    }

    sendVerificationEmail(user, code).catch(console.error);

    sendResponse(res, 201, 'Registration successful. Please check your email for the verification code.', {
      email: user.email,
    });
  } catch (err) {
    next(err);
  }
};

const verifyEmail = async (req, res, next) => {
  try {
    const { email, code } = req.body;

    const user = await User.findOne({ email });
    if (!user) return next(new ApiError(404, 'User not found'));

    if (user.email_verified) {
      return next(new ApiError(400, 'Email already verified'));
    }

    if (!user.verification_code || !user.verification_expiry) {
      return next(new ApiError(400, 'No verification code found. Please request a new one.'));
    }

    if (new Date() > user.verification_expiry) {
      return next(new ApiError(400, 'Verification code has expired. Please request a new one.'));
    }

    if (user.verification_code !== code) {
      return next(new ApiError(400, 'Invalid verification code'));
    }

    user.email_verified      = true;
    user.verification_code   = null;
    user.verification_expiry = null;
    await user.save({ validateBeforeSave: false });

    const token = generateToken({ id: user._id, role: user.role });

    sendWelcomeEmail(user).catch(console.error);

    sendResponse(res, 200, 'Email verified successfully', {
      token,
      user: user.toPublic(),
    });
  } catch (err) {
    next(err);
  }
};

const resendVerificationCode = async (req, res, next) => {
  try {
    const user = await User.findOne({ email: req.body.email });

    if (!user) return sendResponse(res, 200, 'If that email exists a new code has been sent');
    if (user.email_verified) return next(new ApiError(400, 'Email already verified'));

    const code   = generateVerificationCode();
    const expiry = new Date(Date.now() + 15 * 60 * 1000);

    user.verification_code   = code;
    user.verification_expiry = expiry;
    await user.save({ validateBeforeSave: false });

    sendVerificationEmail(user, code).catch(console.error);

    sendResponse(res, 200, 'A new verification code has been sent to your email');
  } catch (err) {
    next(err);
  }
};

const login = async (req, res, next) => {
  try {
    const { email, password } = req.body;

    const user = await User.findOne({ email });
    if (!user || !user.is_active) return next(new ApiError(401, 'Invalid credentials'));

    const match = await user.matchPassword(password);
    if (!match) return next(new ApiError(401, 'Invalid credentials'));

    if (!user.email_verified) {
      return next(new ApiError(403, 'Please verify your email before logging in'));
    }

    const token = generateToken({ id: user._id, role: user.role });

    sendResponse(res, 200, 'Login successful', { token, user: user.toPublic() });
  } catch (err) {
    next(err);
  }
};

const refreshToken = async (req, res, next) => {
  try {
    const { token } = req.body;
    if (!token) return next(new ApiError(400, 'Token is required'));

    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    const user    = await User.findById(decoded.id).select('-password_hash');
    if (!user || !user.is_active) return next(new ApiError(401, 'User not found or inactive'));

    const newToken = generateToken({ id: user._id, role: user.role });
    sendResponse(res, 200, 'Token refreshed', { token: newToken });
  } catch {
    next(new ApiError(401, 'Invalid or expired token'));
  }
};

const changePassword = async (req, res, next) => {
  try {
    const { current_password, new_password } = req.body;

    const user  = await User.findById(req.user._id);
    const match = await user.matchPassword(current_password);
    if (!match) return next(new ApiError(401, 'Current password is incorrect'));

    user.password_hash = new_password;
    await user.save();

    sendResponse(res, 200, 'Password changed successfully');
  } catch (err) {
    next(err);
  }
};

const forgotPassword = async (req, res, next) => {
  try {
    const user = await User.findOne({ email: req.body.email });
    if (!user) return sendResponse(res, 200, 'If that email exists you will receive a reset code');

    const resetToken  = crypto.randomBytes(32).toString('hex');
    const tokenExpiry = Date.now() + 15 * 60 * 1000;

    user.reset_token        = crypto.createHash('sha256').update(resetToken).digest('hex');
    user.reset_token_expiry = tokenExpiry;
    await user.save({ validateBeforeSave: false });

    sendPasswordResetEmail(user, resetToken).catch(console.error);

    sendResponse(res, 200, 'If that email exists you will receive a reset code');
  } catch (err) {
    next(err);
  }
};

const resetPassword = async (req, res, next) => {
  try {
    const { token, new_password } = req.body;

    const hashed = crypto.createHash('sha256').update(token).digest('hex');

    const user = await User.findOne({
      reset_token:        hashed,
      reset_token_expiry: { $gt: Date.now() },
    });
    if (!user) return next(new ApiError(400, 'Invalid or expired reset token'));

    user.password_hash      = new_password;
    user.reset_token        = undefined;
    user.reset_token_expiry = undefined;
    await user.save();

    sendResponse(res, 200, 'Password reset successful');
  } catch (err) {
    next(err);
  }
};

const googleSignIn = async (req, res, next) => {
  try {
    const { id_token, name, email } = req.body;

    const client = new OAuth2Client();
    const ticket = await client.verifyIdToken({
      idToken:  id_token,
      audience: process.env.GOOGLE_CLIENT_ID,
    });

    const payload  = ticket.getPayload();
    const googleId = payload.sub;

    let user = await User.findOne({ email: payload.email });

    if (!user) {
      user = await User.create({
        name:           payload.name  || name  || 'User',
        email:          payload.email || email,
        password_hash:  googleId,
        role:           'patient',
        email_verified: true,
        is_active:      true,
      });
      sendWelcomeEmail(user).catch(console.error);
    } else if (!user.email_verified) {
      user.email_verified = true;
      await user.save({ validateBeforeSave: false });
    }

    if (!user.is_active) {
      return next(new ApiError(403, 'Your account has been deactivated'));
    }

    const token = generateToken({ id: user._id, role: user.role });

    sendResponse(res, 200, 'Google sign in successful', {
      token,
      user: user.toPublic(),
    });
  } catch (err) {
    next(new ApiError(401, 'Invalid Google token'));
  }
};

module.exports = {
  register, login, refreshToken,
  changePassword, forgotPassword, resetPassword,
  verifyEmail, resendVerificationCode,
  googleSignIn,
};