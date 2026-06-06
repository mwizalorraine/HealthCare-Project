const Conversation  = require('../models/Conversation');
const Message       = require('../models/Message');
const ReadReceipt   = require('../models/ReadReceipt');
const ApiError      = require('../utils/apiError');
const { sendResponse }     = require('../utils/apiResponse');
const { notify }           = require('../services/notification.service');
const {
  emitNewMessage,
  emitReactionUpdate,
  emitReceiptUpdate,
} = require('../services/socket.service');

const getConversation = async (req, res, next) => {
  try {
    const conversation = await Conversation.findById(req.params.id)
      .populate('participants', 'name')
      .populate('last_message.sender_id', 'name');
    if (!conversation) return next(new ApiError(404, 'Conversation not found'));
    sendResponse(res, 200, 'Conversation retrieved', conversation);
  } catch (err) {
    next(err);
  }
};

const getMessages = async (req, res, next) => {
  try {
    const { page = 1, limit = 30 } = req.query;

    const messages = await Message.find({ conversation_id: req.params.id })
      .populate('sender_id', 'name')
      .populate('reply_to', 'content sender_id message_type')
      .sort({ createdAt: -1 })
      .skip((page - 1) * limit)
      .limit(parseInt(limit));

    sendResponse(res, 200, 'Messages retrieved', messages.reverse());
  } catch (err) {
    next(err);
  }
};

const sendMessage = async (req, res, next) => {
  try {
    const { message_type, content, reply_to } = req.body;
    const conversationId = req.params.id;

    const conversation = await Conversation.findById(conversationId);
    if (!conversation) return next(new ApiError(404, 'Conversation not found'));
    if (conversation.status === 'closed') return next(new ApiError(400, 'Conversation is closed'));

    const messageContent = message_type === 'image' && req.file
      ? req.file.path
      : content;

    const message = await Message.create({
      conversation_id: conversationId,
      sender_id:       req.user._id,
      message_type,
      content:         messageContent,
      reply_to:        reply_to || null,
    });

    await message.populate('sender_id', 'name');
    if (reply_to) await message.populate('reply_to', 'content sender_id message_type');

    await Conversation.findByIdAndUpdate(conversationId, {
      last_message: {
        content:    messageContent,
        sender_id:  req.user._id,
        created_at: message.createdAt,
      },
      updatedAt: new Date(),
    });

    emitNewMessage(conversationId, message);

    const recipients = conversation.participants.filter(
      (p) => p.toString() !== req.user._id.toString()
    );
    if (recipients.length) {
      await notify(recipients[0], 'chat_message', message.content.substring(0, 80), {
        conversationId, messageId: message._id.toString(),
      });
    }

    sendResponse(res, 201, 'Message sent', message);
  } catch (err) {
    next(err);
  }
};

const addReaction = async (req, res, next) => {
  try {
    const { emoji } = req.body;
    const { messageId } = req.params;

    const message = await Message.findByIdAndUpdate(
      messageId,
      { $pull: { reactions: { user_id: req.user._id } } },
      { new: false }
    );
    if (!message) return next(new ApiError(404, 'Message not found'));

    const updated = await Message.findByIdAndUpdate(
      messageId,
      { $push: { reactions: { user_id: req.user._id, emoji } } },
      { new: true }
    );

    emitReactionUpdate(req.params.id, messageId, updated.reactions);

    sendResponse(res, 200, 'Reaction added', updated.reactions);
  } catch (err) {
    next(err);
  }
};

const markRead = async (req, res, next) => {
  try {
    const conversationId = req.params.id;

    const unread = await Message.find({
      conversation_id: conversationId,
      sender_id:       { $ne: req.user._id },
      is_read:         false,
    }).select('_id');

    if (!unread.length) return sendResponse(res, 200, 'No unread messages');

    const receipts = unread.map((m) => ({
      message_id: m._id,
      user_id:    req.user._id,
      read_at:    new Date(),
    }));

    await Promise.all([
      ReadReceipt.insertMany(receipts, { ordered: false }),
      Message.updateMany(
        { _id: { $in: unread.map((m) => m._id) } },
        { is_read: true }
      ),
    ]);

    unread.forEach((m) => {
      emitReceiptUpdate(conversationId, m._id.toString(), req.user._id.toString(), new Date());
    });

    sendResponse(res, 200, 'Messages marked as read');
  } catch (err) {
    next(err);
  }
};

// Find the conversation linked to a specific order.
const getConversationByOrder = async (req, res, next) => {
  try {
    const conversation = await Conversation.findOne({ order_id: req.params.orderId })
      .populate('participants', 'name');
    if (!conversation) return next(new ApiError(404, 'No conversation for this order yet'));
    sendResponse(res, 200, 'Conversation retrieved', conversation);
  } catch (err) {
    next(err);
  }
};

// Get or create a conversation for an order.
// Both patient and pharmacy admin can call this — it creates one conversation
// per order (even before a delivery is dispatched).
const getOrCreateConversation = async (req, res, next) => {
  try {
    const { order_id } = req.body;
    if (!order_id) return next(new ApiError(400, 'order_id is required'));

    const Order = require('../models/Order');
    const Pharmacy = require('../models/Pharmacy');

    const order = await Order.findById(order_id);
    if (!order) return next(new ApiError(404, 'Order not found'));

    // Check caller has access: must be the patient or any of the pharmacy admin's pharmacies
    const isPatient = order.patient_id.toString() === req.user._id.toString();
    let isPharmacy = false;
    if (!isPatient) {
      const pharmacies = await Pharmacy.find({ user_id: req.user._id }).select('_id');
      isPharmacy = pharmacies.some(
        (ph) => ph._id.toString() === order.pharmacy_id.toString()
      );
    }
    if (!isPatient && !isPharmacy) return next(new ApiError(403, 'Access denied'));

    // Find existing conversation or create a new one
    let conversation = await Conversation.findOne({ order_id });

    if (!conversation) {
      // Build participant list: always include the patient; add caller if they are the pharmacy admin
      const participants = [order.patient_id];
      if (isPharmacy) participants.push(req.user._id);

      conversation = await Conversation.create({
        order_id,
        participants,
        status: 'active',
      });
    } else if (isPharmacy) {
      // Ensure pharmacy admin is in the participants list
      const alreadyIn = conversation.participants.some(
        (p) => p.toString() === req.user._id.toString()
      );
      if (!alreadyIn) {
        conversation.participants.push(req.user._id);
        await conversation.save();
      }
    }

    await conversation.populate('participants', 'name');
    sendResponse(res, 200, 'Conversation retrieved', conversation);
  } catch (err) {
    next(err);
  }
};

module.exports = { getConversation, getMessages, sendMessage, addReaction, markRead, getConversationByOrder, getOrCreateConversation };