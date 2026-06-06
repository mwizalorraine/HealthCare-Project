const mongoose = require('mongoose');

const inventorySchema = new mongoose.Schema(
  {
    pharmacy_id: { type: mongoose.Schema.Types.ObjectId, ref: 'Pharmacy', required: true },
    medicine_id: { type: mongoose.Schema.Types.ObjectId, ref: 'Medicine', required: true },
    price:       { type: Number, required: true, min: 0 },
    quantity:    { type: Number, default: 0, min: 0 },
    in_stock:    { type: Boolean, default: false },
    expiry_date: { type: Date, default: null },
  },
  { timestamps: true }
);

inventorySchema.index({ pharmacy_id: 1, medicine_id: 1 }, { unique: true });
inventorySchema.index({ medicine_id: 1, in_stock: 1 });
inventorySchema.index({ pharmacy_id: 1, in_stock: 1 });

inventorySchema.pre('save', function (next) {
  this.in_stock = this.quantity > 0;
  next();
});

module.exports = mongoose.model('Inventory', inventorySchema);