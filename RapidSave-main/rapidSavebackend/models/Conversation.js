const mongoose = require('mongoose');

const conversationSchema = new mongoose.Schema(
  {
    delivery_id: { type: mongoose.Schema.Types.ObjectId, ref: 'Delivery', default: null },
    order_id:    { type: mongoose.Schema.Types.ObjectId, ref: 'Order', required: true },
    participants: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
    status:      { type: String, enum: ['active', 'closed'], default: 'active' },
    last_message: {
      content:    { type: String, default: null },
      sender_id:  { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null },
      created_at: { type: Date, default: null },
    },
  },
  { timestamps: true }
);

conversationSchema.index({ order_id: 1 }, { unique: true });          // one conversation per order
conversationSchema.index({ delivery_id: 1 }, { sparse: true });        // sparse: allows many nulls
conversationSchema.index({ participants: 1, status: 1 });
conversationSchema.index({ updatedAt: -1 });

module.exports = mongoose.model('Conversation', conversationSchema);