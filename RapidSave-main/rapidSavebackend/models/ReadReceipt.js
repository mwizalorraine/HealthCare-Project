const mongoose = require('mongoose');

const readReceiptSchema = new mongoose.Schema(
  {
    message_id: { type: mongoose.Schema.Types.ObjectId, ref: 'Message', required: true },
    user_id:    { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    read_at:    { type: Date, default: Date.now },
  },
  { timestamps: false }
);

readReceiptSchema.index({ message_id: 1, user_id: 1 }, { unique: true });
readReceiptSchema.index({ user_id: 1 });

module.exports = mongoose.model('ReadReceipt', readReceiptSchema);