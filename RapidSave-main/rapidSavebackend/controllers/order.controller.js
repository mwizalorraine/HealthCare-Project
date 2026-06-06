const mongoose     = require('mongoose');
const cloudinary   = require('cloudinary').v2;
const Order        = require('../models/Order');
const OrderItem    = require('../models/OrderItem');
const Inventory    = require('../models/Inventory');
const Pharmacy     = require('../models/Pharmacy');
const User         = require('../models/User');
const ApiError     = require('../utils/apiError');
const { sendResponse }             = require('../utils/apiResponse');
const { notify }                   = require('../services/notification.service');
const {
  sendOrderStatusEmail,
  sendPaymentVerificationEmail,
} = require('../services/email.service');

const createOrder = async (req, res, next) => {
  const session = await mongoose.startSession();
  session.startTransaction();

  let order      = null;
  let pharmacyId = null;
  let orderType  = null;

  try {
    const { pharmacy_id, type, items, notes } = req.body;
    pharmacyId = pharmacy_id;
    orderType  = type;

    const parsedItems = typeof items === 'string' ? JSON.parse(items) : items;

    const inventoryIds   = parsedItems.map((i) => i.inventory_id);
    const inventoryItems = await Inventory.find({
      _id:        { $in: inventoryIds },
      pharmacy_id,
      in_stock:   true,
    }).session(session);

    if (inventoryItems.length !== parsedItems.length) {
      await session.abortTransaction();
      session.endSession();
      return next(new ApiError(400, 'One or more items are unavailable'));
    }

    // Validate each requested quantity against available stock
    for (const item of parsedItems) {
      const inv = inventoryItems.find((i) => i._id.toString() === item.inventory_id);
      if (item.quantity > inv.quantity) {
        await session.abortTransaction();
        session.endSession();
        return next(new ApiError(400, `Insufficient stock — only ${inv.quantity} unit(s) available`));
      }
    }

    let total_amount = 0;
    const orderItemsData = parsedItems.map((item) => {
      const inv = inventoryItems.find((i) => i._id.toString() === item.inventory_id);
      total_amount += inv.price * item.quantity;
      return { inventory_id: inv._id, quantity: item.quantity, unit_price: inv.price };
    });

    const prescription_images = req.files
      ? req.files.map((f) => ({ url: f.path, public_id: f.filename }))
      : [];

    const [created] = await Order.create(
      [{ patient_id: req.user._id, pharmacy_id, type, total_amount, notes, prescription_images }],
      { session }
    );
    order = created;

    const orderItemsDocs = orderItemsData.map((d) => ({ ...d, order_id: order._id }));
    await OrderItem.insertMany(orderItemsDocs, { session });

    // Deduct inventory quantities within the transaction
    await Promise.all(parsedItems.map(async (item) => {
      const inv = inventoryItems.find((i) => i._id.toString() === item.inventory_id);
      const newQty = inv.quantity - item.quantity;
      return Inventory.findByIdAndUpdate(
        inv._id,
        { quantity: newQty, in_stock: newQty > 0 },
        { session }
      );
    }));

    // Commit first — transaction is done
    await session.commitTransaction();
  } catch (err) {
    // Only abort if we haven't committed yet
    try { await session.abortTransaction(); } catch (_) {}
    session.endSession();
    return next(err);
  }

  // End session BEFORE side effects so a notification failure
  // can never trigger abortTransaction on an already-committed session
  session.endSession();

  // Side effects outside the transaction — failures don't crash the server
  try {
    const pharmacy = await Pharmacy.findById(pharmacyId).select('user_id name');
    if (pharmacy) {
      await notify(pharmacy.user_id, 'order_update', `New ${orderType} order received`, {
        orderId: order._id.toString(),
      });
    }
  } catch (_) {
    // Notification failure must not fail the order
  }

  sendResponse(res, 201, 'Order placed successfully', order);
};

const getMyOrders = async (req, res, next) => {
  try {
    const { page = 1, limit = 10, status } = req.query;
    const filter = { patient_id: req.user._id };
    if (status) filter.status = status;

    const [orders, total] = await Promise.all([
      Order.find(filter)
        .populate('pharmacy_id', 'name address phone')
        .skip((page - 1) * limit)
        .limit(parseInt(limit))
        .sort({ createdAt: -1 }),
      Order.countDocuments(filter),
    ]);

    sendResponse(res, 200, 'Orders retrieved', {
      orders, total, page: parseInt(page), pages: Math.ceil(total / limit),
    });
  } catch (err) {
    next(err);
  }
};

const getPharmacyOrders = async (req, res, next) => {
  try {
    const { page = 1, limit = 10, status, pharmacy_id } = req.query;

    let pharmacyObjectId;
    if (pharmacy_id) {
      // Use the explicitly provided pharmacy_id (validated ownership below)
      const ph = await Pharmacy.findOne({ _id: pharmacy_id, user_id: req.user._id });
      if (!ph) return next(new ApiError(403, 'Pharmacy not found or not yours'));
      pharmacyObjectId = ph._id;
    } else {
      const pharmacy = await Pharmacy.findOne({ user_id: req.user._id });
      if (!pharmacy) return next(new ApiError(404, 'Pharmacy not found'));
      pharmacyObjectId = pharmacy._id;
    }

    const filter = { pharmacy_id: pharmacyObjectId };
    if (status) filter.status = status;

    const [orders, total] = await Promise.all([
      Order.find(filter)
        .populate('patient_id', 'name email phone')
        .skip((page - 1) * limit)
        .limit(parseInt(limit))
        .sort({ createdAt: -1 }),
      Order.countDocuments(filter),
    ]);

    sendResponse(res, 200, 'Orders retrieved', {
      orders, total, page: parseInt(page), pages: Math.ceil(total / limit),
    });
  } catch (err) {
    next(err);
  }
};

const getOrderById = async (req, res, next) => {
  try {
    const order = await Order.findById(req.params.id)
      .populate('patient_id', 'name email phone')
      .populate('pharmacy_id', 'name address phone');
    if (!order) return next(new ApiError(404, 'Order not found'));

    const items = await OrderItem.find({ order_id: order._id }).populate({
      path: 'inventory_id',
      populate: { path: 'medicine_id', select: 'name category unit' },
    });

    sendResponse(res, 200, 'Order retrieved', { order, items });
  } catch (err) {
    next(err);
  }
};

const updateOrderStatus = async (req, res, next) => {
  try {
    const { status } = req.body;

    const order = await Order.findById(req.params.id);
    if (!order) return next(new ApiError(404, 'Order not found'));

    if (
      status !== 'cancelled' &&
      order.payment.status !== 'verified'
    ) {
      return next(new ApiError(400, 'Cannot progress order until payment is verified'));
    }

    // Restore inventory when an order is cancelled before completion/delivery
    if (status === 'cancelled' && order.status !== 'completed' && order.status !== 'delivered') {
      const items = await OrderItem.find({ order_id: order._id });
      await Promise.all(items.map(async (item) => {
        const inv = await Inventory.findById(item.inventory_id);
        if (inv) {
          const newQty = inv.quantity + item.quantity;
          await Inventory.findByIdAndUpdate(item.inventory_id, { quantity: newQty, in_stock: true });
        }
      }));
    }

    order.status = status;
    await order.save();

    const patient = await User.findById(order.patient_id).select('name email');

    await Promise.all([
      notify(order.patient_id, 'order_update', `Your order is now ${status}`, {
        orderId: order._id.toString(), status,
      }),
      sendOrderStatusEmail(patient, order, status).catch(console.error),
    ]);

    sendResponse(res, 200, 'Order status updated', order);
  } catch (err) {
    next(err);
  }
};

const uploadPaymentProof = async (req, res, next) => {
  try {
    if (!req.file) return next(new ApiError(400, 'Payment proof file is required'));

    const order = await Order.findOne({
      _id:        req.params.id,
      patient_id: req.user._id,
    });
    if (!order) return next(new ApiError(404, 'Order not found'));

    if (order.payment.status === 'verified') {
      return next(new ApiError(400, 'Payment already verified'));
    }

    if (order.payment.proof.public_id) {
      await cloudinary.uploader.destroy(order.payment.proof.public_id);
    }

    order.payment.proof     = { url: req.file.path, public_id: req.file.filename };
    order.payment.provider  = req.body.provider;
    order.payment.reference = req.body.reference;
    order.payment.status    = 'pending_verification';
    await order.save();

    const pharmacy = await Pharmacy.findById(order.pharmacy_id).select('user_id');
    await notify(pharmacy.user_id, 'order_update', 'Payment proof submitted — awaiting your verification', {
      orderId: order._id.toString(),
    });

    sendResponse(res, 200, 'Payment proof uploaded', order);
  } catch (err) {
    next(err);
  }
};

const verifyPayment = async (req, res, next) => {
  try {
    const { action, rejected_reason } = req.body;

    const pharmacy = await Pharmacy.findOne({ user_id: req.user._id });
    if (!pharmacy) return next(new ApiError(404, 'Pharmacy not found'));

    const order = await Order.findOne({
      _id:         req.params.id,
      pharmacy_id: pharmacy._id,
    });
    if (!order) return next(new ApiError(404, 'Order not found'));

    if (order.payment.status !== 'pending_verification') {
      return next(new ApiError(400, 'No pending payment proof to review'));
    }

    const patient = await User.findById(order.patient_id).select('name email');

    if (action === 'verify') {
      order.payment.status          = 'verified';
      order.payment.verified_at     = new Date();
      order.payment.rejected_reason = null;

      await Promise.all([
        notify(order.patient_id, 'order_update', 'Your payment has been verified', {
          orderId: order._id.toString(),
        }),
        sendPaymentVerificationEmail(patient, order, 'verify').catch(console.error),
      ]);
    } else {
      order.payment.status          = 'rejected';
      order.payment.rejected_reason = rejected_reason;

      await Promise.all([
        notify(order.patient_id, 'order_update', `Payment rejected: ${rejected_reason}`, {
          orderId: order._id.toString(),
        }),
        sendPaymentVerificationEmail(patient, order, 'reject', rejected_reason).catch(console.error),
      ]);
    }

    await order.save();
    sendResponse(res, 200, `Payment ${action === 'verify' ? 'verified' : 'rejected'}`, order);
  } catch (err) {
    next(err);
  }
};

const getPendingPayments = async (req, res, next) => {
  try {
    const { pharmacy_id } = req.query;
    let pharmacyObjectId;
    if (pharmacy_id) {
      const ph = await Pharmacy.findOne({ _id: pharmacy_id, user_id: req.user._id });
      if (!ph) return next(new ApiError(403, 'Pharmacy not found or not yours'));
      pharmacyObjectId = ph._id;
    } else {
      const pharmacy = await Pharmacy.findOne({ user_id: req.user._id });
      if (!pharmacy) return next(new ApiError(404, 'Pharmacy not found'));
      pharmacyObjectId = pharmacy._id;
    }

    const orders = await Order.find({
      pharmacy_id:      pharmacyObjectId,
      'payment.status': 'pending_verification',
    })
      .populate('patient_id', 'name email phone')
      .sort({ createdAt: -1 });

    sendResponse(res, 200, 'Pending payments retrieved', orders);
  } catch (err) {
    next(err);
  }
};

module.exports = {
  createOrder, getMyOrders, getOrderById,
  updateOrderStatus, getPharmacyOrders,
  uploadPaymentProof, verifyPayment, getPendingPayments,
};