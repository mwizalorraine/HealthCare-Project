const mongoose = require('mongoose');

const orderItemSchema = new mongoose.Schema(
  {
    order_id:     { type: mongoose.Schema.Types.ObjectId, ref: 'Order', required: true },
    inventory_id: { type: mongoose.Schema.Types.ObjectId, ref: 'Inventory', required: true },
    quantity:     { type: Number, required: true, min: 1 },
    unit_price:   { type: Number, required: true, min: 0 },
  },
  { timestamps: false }
);

orderItemSchema.index({ order_id: 1 });

module.exports = mongoose.model('OrderItem', orderItemSchema);