const { getIO } = require('../config/socket');
const EVENTS    = require('../constants/events');

const emitToConversation = (conversationId, event, data) => {
  getIO().to(`conversation:${conversationId}`).emit(event, data);
};

const emitNewMessage = (conversationId, message) => {
  emitToConversation(conversationId, EVENTS.NEW_MESSAGE, message);
};

const emitReactionUpdate = (conversationId, messageId, reactions) => {
  emitToConversation(conversationId, EVENTS.REACTION_UPDATE, { messageId, reactions });
};

const emitReceiptUpdate = (conversationId, messageId, userId, readAt) => {
  emitToConversation(conversationId, EVENTS.RECEIPT_UPDATE, { messageId, userId, readAt });
};

const emitConversationClosed = (conversationId) => {
  emitToConversation(conversationId, EVENTS.CONVERSATION_CLOSED, { conversationId });
};

const emitToDelivery = (deliveryId, event, data) => {
  getIO().to(`delivery:${deliveryId}`).emit(event, data);
};

const emitDeliveryStatusUpdate = (deliveryId, status) => {
  emitToDelivery(deliveryId, EVENTS.DELIVERY_STATUS_UPDATE, { delivery_id: deliveryId, status });
};

const emitDriverLocation = (deliveryId, lat, lng) => {
  emitToDelivery(deliveryId, EVENTS.DRIVER_LOCATION, { delivery_id: deliveryId, lat, lng });
};

module.exports = {
  emitToConversation,
  emitNewMessage,
  emitReactionUpdate,
  emitReceiptUpdate,
  emitConversationClosed,
  emitToDelivery,
  emitDeliveryStatusUpdate,
  emitDriverLocation,
};