const Medicine = require('../models/Medicine');
const ApiError  = require('../utils/apiError');
const { sendResponse } = require('../utils/apiResponse');

const createMedicine = async (req, res, next) => {
  try {
    const medicine = await Medicine.create(req.body);
    sendResponse(res, 201, 'Medicine created', medicine);
  } catch (err) {
    next(err);
  }
};

const getAllMedicines = async (req, res, next) => {
  try {
    const { page = 1, limit = 20, category } = req.query;
    const filter = category ? { category } : {};

    const [medicines, total] = await Promise.all([
      Medicine.find(filter)
        .skip((page - 1) * limit)
        .limit(parseInt(limit))
        .sort({ name: 1 }),
      Medicine.countDocuments(filter),
    ]);

    sendResponse(res, 200, 'Medicines retrieved', {
      medicines, total, page: parseInt(page), pages: Math.ceil(total / limit),
    });
  } catch (err) {
    next(err);
  }
};

const getMedicineById = async (req, res, next) => {
  try {
    const medicine = await Medicine.findById(req.params.id);
    if (!medicine) return next(new ApiError(404, 'Medicine not found'));
    sendResponse(res, 200, 'Medicine retrieved', medicine);
  } catch (err) {
    next(err);
  }
};

const updateMedicine = async (req, res, next) => {
  try {
    const medicine = await Medicine.findByIdAndUpdate(req.params.id, req.body, {
      new: true, runValidators: true,
    });
    if (!medicine) return next(new ApiError(404, 'Medicine not found'));
    sendResponse(res, 200, 'Medicine updated', medicine);
  } catch (err) {
    next(err);
  }
};

const searchMedicines = async (req, res, next) => {
  try {
    const { q, page = 1, limit = 20 } = req.query;

    const [medicines, total] = await Promise.all([
      Medicine.find(
        { $text: { $search: q } },
        { score: { $meta: 'textScore' } }
      )
        .sort({ score: { $meta: 'textScore' } })
        .skip((page - 1) * limit)
        .limit(parseInt(limit)),
      Medicine.countDocuments({ $text: { $search: q } }),
    ]);

    sendResponse(res, 200, 'Search results', {
      medicines, total, page: parseInt(page), pages: Math.ceil(total / limit),
    });
  } catch (err) {
    next(err);
  }
};

module.exports = { createMedicine, getAllMedicines, getMedicineById, updateMedicine, searchMedicines };