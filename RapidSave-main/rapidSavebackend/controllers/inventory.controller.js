const Inventory = require('../models/Inventory');
const Pharmacy  = require('../models/Pharmacy');
const ApiError  = require('../utils/apiError');
const { sendResponse } = require('../utils/apiResponse');

const upsertInventory = async (req, res, next) => {
  try {
    const pharmacy = await Pharmacy.findOne({ user_id: req.user._id });
    if (!pharmacy) return next(new ApiError(404, 'Pharmacy not found'));

    const { medicine_id, price, quantity, expiry_date } = req.body;

    // Set in_stock explicitly because findOneAndUpdate does NOT trigger
    // Mongoose pre-save hooks, so the auto-hook (in_stock = quantity > 0)
    // never runs. We calculate it manually here.
    const inventory = await Inventory.findOneAndUpdate(
      { pharmacy_id: pharmacy._id, medicine_id },
      { price, quantity, expiry_date, in_stock: quantity > 0 },
      { upsert: true, new: true, runValidators: true, setDefaultsOnInsert: true }
    );

    sendResponse(res, 200, 'Inventory updated', inventory);
  } catch (err) {
    next(err);
  }
};

const getPharmacyInventory = async (req, res, next) => {
  try {
    const { page = 1, limit = 20, in_stock } = req.query;
    const filter = { pharmacy_id: req.params.pharmacyId };
    if (in_stock !== undefined) filter.in_stock = in_stock === 'true';

    const [items, total] = await Promise.all([
      Inventory.find(filter)
        .populate('medicine_id', 'name generic_name category unit')
        .skip((page - 1) * limit)
        .limit(parseInt(limit))
        .sort({ updatedAt: -1 }),
      Inventory.countDocuments(filter),
    ]);

    sendResponse(res, 200, 'Inventory retrieved', {
      items, total, page: parseInt(page), pages: Math.ceil(total / limit),
    });
  } catch (err) {
    next(err);
  }
};

const getMedicineAvailability = async (req, res, next) => {
  try {
    const items = await Inventory.find({
      medicine_id: req.params.medicineId,
      in_stock:    true,
    })
      .populate('pharmacy_id', 'name address location phone is_open')
      .sort({ price: 1 });

    sendResponse(res, 200, 'Availability retrieved', items);
  } catch (err) {
    next(err);
  }
};

const deleteInventoryItem = async (req, res, next) => {
  try {
    const pharmacy = await Pharmacy.findOne({ user_id: req.user._id });
    if (!pharmacy) return next(new ApiError(404, 'Pharmacy not found'));

    const item = await Inventory.findOneAndDelete({
      _id: req.params.id,
      pharmacy_id: pharmacy._id,
    });
    if (!item) return next(new ApiError(404, 'Inventory item not found'));

    sendResponse(res, 200, 'Inventory item removed');
  } catch (err) {
    next(err);
  }
};

module.exports = { upsertInventory, getPharmacyInventory, getMedicineAvailability, deleteInventoryItem };