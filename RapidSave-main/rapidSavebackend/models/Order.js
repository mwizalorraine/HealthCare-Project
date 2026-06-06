const mongoose = require('mongoose');

const orderSchema = new mongoose.Schema(
  {
    patient_id:   { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    pharmacy_id:  { type: mongoose.Schema.Types.ObjectId, ref: 'Pharmacy', required: true },
    type:         { type: String, enum: ['reservation', 'delivery'], required: true },
    status:       { type: String, enum: ['pending', 'confirmed', 'ready', 'completed', 'cancelled'], default: 'pending' },
    total_amount: { type: Number, required: true, min: 0 },
    notes:        { type: String, default: null },
    prescription_images: [
      {
        url:       { type: String, required: true },
        public_id: { type: String, required: true },
      },
    ],
    payment: {
      status:      { type: String, enum: ['unpaid', 'pending_verification', 'verified', 'rejected'], default: 'unpaid' },
      proof:       { url: { type: String, default: null }, public_id: { type: String, default: null } },
      provider:    { type: String, default: null },
      reference:   { type: String, default: null },
      verified_at: { type: Date, default: null },
      rejected_reason: { type: String, default: null },
    },
  },
  { timestamps: true }
);

orderSchema.index({ patient_id: 1, status: 1 });
orderSchema.index({ pharmacy_id: 1, status: 1 });
orderSchema.index({ 'payment.status': 1 });
orderSchema.index({ createdAt: -1 });

module.exports = mongoose.model('Order', orderSchema);