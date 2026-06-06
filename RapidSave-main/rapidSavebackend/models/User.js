const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema(
  {
    name:          { type: String, required: true, trim: true },
    email:         { type: String, required: true, unique: true, lowercase: true, trim: true },
    password_hash: { type: String, required: true },
    role:          { type: String, enum: ['patient', 'pharmacy_admin', 'admin'], required: true },
    phone:         { type: String, trim: true, default: null },
    is_active:     { type: Boolean, default: true },
    email_verified:       { type: Boolean, default: false },
    verification_code:    { type: String, default: null },
    verification_expiry:  { type: Date, default: null },
    reset_token:          { type: String, default: null },
    reset_token_expiry:   { type: Date, default: null },
  },
  { timestamps: true }
);

userSchema.index({ role: 1 });

userSchema.pre('save', async function (next) {
  if (!this.isModified('password_hash')) return next();
  this.password_hash = await bcrypt.hash(this.password_hash, 12);
  next();
});

userSchema.methods.matchPassword = function (plain) {
  return bcrypt.compare(plain, this.password_hash);
};

userSchema.methods.toPublic = function () {
  const obj = this.toObject();
  delete obj.password_hash;
  delete obj.verification_code;
  delete obj.verification_expiry;
  delete obj.reset_token;
  delete obj.reset_token_expiry;
  return obj;
};

module.exports = mongoose.model('User', userSchema);