const jwt         = require('jsonwebtoken');
const User        = require('../models/User');
const ApiError    = require('../utils/apiError');
const ROLES       = require('../constants/roles');

const protect = async (req, res, next) => {
  try {
    const header = req.headers.authorization;
    if (!header || !header.startsWith('Bearer ')) {
      return next(new ApiError(401, 'Not authorized, no token'));
    }

    const token   = header.split(' ')[1];
    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    const user = await User.findById(decoded.id).select('-password_hash');
    if (!user || !user.is_active) {
      return next(new ApiError(401, 'Not authorized, user inactive or not found'));
    }

    req.user = user;
    next();
  } catch {
    next(new ApiError(401, 'Not authorized, invalid token'));
  }
};

const restrictTo = (...roles) => (req, res, next) => {
  if (!roles.includes(req.user.role)) {
    return next(new ApiError(403, 'You do not have permission to perform this action'));
  }
  next();
};

const adminOnly         = restrictTo(ROLES.ADMIN);
const pharmacyAdminOnly = restrictTo(ROLES.PHARMACY_ADMIN);
const patientOnly       = restrictTo(ROLES.PATIENT);

module.exports = { protect, restrictTo, adminOnly, pharmacyAdminOnly, patientOnly };