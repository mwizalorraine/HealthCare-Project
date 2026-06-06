const mongoose = require('mongoose');

const deliverySchema = new mongoose.Schema(
  {
    order_id: { type: mongoose.Schema.Types.ObjectId, ref: 'Order', required: true},
    address:  { type: String, required: true },
    destination: {
      type:        { type: String, enum: ['Point'], default: 'Point' },
      coordinates: { type: [Number], required: true },
    },
    status:       { type: String, enum: ['assigned', 'in_transit', 'delivered', 'failed'], default: 'assigned' },
    rider_name:   { type: String, default: null },
    rider_phone:  { type: String, default: null },
    estimated_at: { type: Date, default: null },
    delivered_at: { type: Date, default: null },
  },
  { timestamps: true }
);

deliverySchema.index({ order_id: 1 });
deliverySchema.index({ status: 1 });
deliverySchema.index({ destination: '2dsphere' });

module.exports = mongoose.model('Delivery', deliverySchema);