const Delivery      = require('../models/Delivery');
const Order         = require('../models/Order');
const Conversation  = require('../models/Conversation');
const ApiError      = require('../utils/apiError');
const { sendResponse }       = require('../utils/apiResponse');
const { notify }             = require('../services/notification.service');
const { emitConversationClosed, emitDeliveryStatusUpdate } = require('../services/socket.service');

const createDelivery = async (req, res, next) => {
  try {
    const { order_id, address, coordinates, rider_name, rider_phone, estimated_at } = req.body;

    const order = await Order.findById(order_id);
    if (!order) return next(new ApiError(404, 'Order not found'));
    if (order.type !== 'delivery') return next(new ApiError(400, 'Order is not a delivery type'));

    const existing = await Delivery.findOne({ order_id });
    if (existing) return next(new ApiError(409, 'Delivery already exists for this order'));

    const delivery = await Delivery.create({
      order_id, address, rider_name, rider_phone, estimated_at,
      destination: { type: 'Point', coordinates },
    });

    // Link delivery to existing conversation or create a new one
    const existingConv = await Conversation.findOne({ order_id: order._id });
    if (existingConv) {
      await Conversation.findByIdAndUpdate(existingConv._id, { delivery_id: delivery._id });
    } else {
      await Conversation.create({
        delivery_id:  delivery._id,
        order_id:     order._id,
        participants: [order.patient_id],
        status:       'active',
      });
    }

    await notify(order.patient_id, 'delivery_update', 'Your delivery has been assigned a rider', {
      orderId:    order._id.toString(),
      deliveryId: delivery._id.toString(),
    });

    sendResponse(res, 201, 'Delivery created', delivery);
  } catch (err) {
    next(err);
  }
};

const getDeliveryById = async (req, res, next) => {
  try {
    const delivery = await Delivery.findById(req.params.id).populate('order_id');
    if (!delivery) return next(new ApiError(404, 'Delivery not found'));

    const conversation = await Conversation.findOne({ delivery_id: delivery._id }).select('_id');
    const result = delivery.toObject();
    result.conversation_id = conversation?._id ?? null;

    sendResponse(res, 200, 'Delivery retrieved', result);
  } catch (err) {
    next(err);
  }
};

const getDeliveryByOrder = async (req, res, next) => {
  try {
    const delivery = await Delivery.findOne({ order_id: req.params.orderId })
      .populate('order_id');
    if (!delivery) return next(new ApiError(404, 'Delivery not found'));

    const conversation = await Conversation.findOne({ delivery_id: delivery._id }).select('_id');
    const result = delivery.toObject();
    result.conversation_id = conversation?._id ?? null;

    sendResponse(res, 200, 'Delivery retrieved', result);
  } catch (err) {
    next(err);
  }
};

const updateDeliveryStatus = async (req, res, next) => {
  try {
    const { status } = req.body;
    const delivery = await Delivery.findByIdAndUpdate(
      req.params.id,
      {
        status,
        ...(status === 'delivered' && { delivered_at: new Date() }),
      },
      { new: true }
    );
    if (!delivery) return next(new ApiError(404, 'Delivery not found'));

    const order = await Order.findById(delivery.order_id);

    // Push real-time status to patient's tracking screen
    emitDeliveryStatusUpdate(delivery._id.toString(), status);

    await notify(order.patient_id, 'delivery_update', `Delivery status: ${status}`, {
      deliveryId: delivery._id.toString(), status,
    });

    // Complete the order automatically when delivered
    if (status === 'delivered') {
      await Order.findByIdAndUpdate(delivery.order_id, { status: 'completed' });
    }

    if (status === 'delivered' || status === 'failed') {
      const conversation = await Conversation.findOneAndUpdate(
        { delivery_id: delivery._id },
        { status: 'closed' },
        { new: true }
      );
      if (conversation) emitConversationClosed(conversation._id.toString());
    }

    sendResponse(res, 200, 'Delivery status updated', delivery);
  } catch (err) {
    next(err);
  }
};

const getMyDeliveries = async (req, res, next) => {
  try {
    const orders = await Order.find({ patient_id: req.user._id, type: 'delivery' }).select('_id');
    const orderIds = orders.map((o) => o._id);

    const deliveries = await Delivery.find({ order_id: { $in: orderIds } })
      .populate('order_id')
      .sort({ createdAt: -1 });

    sendResponse(res, 200, 'Deliveries retrieved', deliveries);
  } catch (err) {
    next(err);
  }
};

module.exports = { createDelivery, getDeliveryById, getDeliveryByOrder, updateDeliveryStatus, getMyDeliveries };