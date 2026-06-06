const mongoose = require('mongoose');

const medicineSchema = new mongoose.Schema(
  {
    name:         { type: String, required: true, trim: true },
    generic_name: { type: String, trim: true, default: null },
    category:     { type: String, trim: true, default: null },
    description:  { type: String, default: null },
    manufacturer: { type: String, trim: true, default: null },
    unit:         { type: String, required: true, trim: true },
  },
  { timestamps: true }
);

medicineSchema.index({ name: 'text', generic_name: 'text' });
medicineSchema.index({ category: 1 });

module.exports = mongoose.model('Medicine', medicineSchema);