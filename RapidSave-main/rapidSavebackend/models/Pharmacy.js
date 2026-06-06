const mongoose = require('mongoose');

const pharmacySchema = new mongoose.Schema(
  {
    user_id:        { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    name:           { type: String, required: true, trim: true },
    license_number: { type: String, required: true, unique: true, trim: true },
    address:        { type: String, required: true },
    location: {
      type:        { type: String, enum: ['Point'], default: 'Point' },
      coordinates: { type: [Number], required: true },
    },
    phone:                { type: String, trim: true, default: null },
    accepted_insurances:  { type: [String], default: [] },
    is_verified:          { type: Boolean, default: false },
    is_open:              { type: Boolean, default: false },
  },
  { timestamps: true }
);

pharmacySchema.index({ location: '2dsphere' });
pharmacySchema.index({ is_verified: 1, is_open: 1 });

module.exports = mongoose.model('Pharmacy', pharmacySchema);