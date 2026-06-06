const mongoose = require('mongoose');

const deviceTokenSchema = new mongoose.Schema(
  {
    user_id:   { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    fcm_token: { type: String, required: true },
    platform:  { type: String, enum: ['android', 'ios', 'web'], required: true },
    is_active: { type: Boolean, default: true },
  },
  { timestamps: true }
);

deviceTokenSchema.index({ user_id: 1, is_active: 1 });
deviceTokenSchema.index({ fcm_token: 1 }, { unique: true });

module.exports = mongoose.model('DeviceToken', deviceTokenSchema);