const mongoose = require('mongoose');

const reactionSchema = new mongoose.Schema(
  {
    user_id: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    emoji:   { type: String, required: true },
  },
  { _id: false }
);

const messageSchema = new mongoose.Schema(
  {
    conversation_id: { type: mongoose.Schema.Types.ObjectId, ref: 'Conversation', required: true },
    sender_id:       { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    reply_to:        { type: mongoose.Schema.Types.ObjectId, ref: 'Message', default: null },
    message_type:    { type: String, enum: ['text', 'image', 'system'], default: 'text' },
    content:         { type: String, required: true },
    reactions:       { type: [reactionSchema], default: [] },
    is_read:         { type: Boolean, default: false },
  },
  { timestamps: true }
);

messageSchema.index({ conversation_id: 1, createdAt: 1 });
messageSchema.index({ sender_id: 1 });
messageSchema.index({ reply_to: 1 });

module.exports = mongoose.model('Message', messageSchema);