const Pharmacy  = require('../models/Pharmacy');
const ApiError  = require('../utils/apiError');
const { sendResponse } = require('../utils/apiResponse');
const { buildNearbyQuery, getDistanceKm } = require('../services/geo.service');

const getMyPharmacies = async (req, res, next) => {
  try {
    const pharmacies = await Pharmacy.find({ user_id: req.user._id }).sort({ createdAt: -1 });
    sendResponse(res, 200, 'Pharmacies retrieved', pharmacies);
  } catch (err) {
    next(err);
  }
};

const toggleOpenById = async (req, res, next) => {
  try {
    const pharmacy = await Pharmacy.findOne({ _id: req.params.id, user_id: req.user._id });
    if (!pharmacy) return next(new ApiError(404, 'Pharmacy not found'));
    pharmacy.is_open = !pharmacy.is_open;
    await pharmacy.save();
    sendResponse(res, 200, `Pharmacy is now ${pharmacy.is_open ? 'open' : 'closed'}`, pharmacy);
  } catch (err) {
    next(err);
  }
};

const updatePharmacyById = async (req, res, next) => {
  try {
    const pharmacy = await Pharmacy.findOneAndUpdate(
      { _id: req.params.id, user_id: req.user._id },
      req.body,
      { new: true, runValidators: true }
    );
    if (!pharmacy) return next(new ApiError(404, 'Pharmacy not found'));
    sendResponse(res, 200, 'Pharmacy updated', pharmacy);
  } catch (err) {
    next(err);
  }
};

const createPharmacy = async (req, res, next) => {
  try {
    const { name, license_number, address, coordinates, phone, accepted_insurances } = req.body;

    const pharmacy = await Pharmacy.create({
      user_id: req.user._id,
      name, license_number, address, phone,
      accepted_insurances: accepted_insurances || [],
      location: { type: 'Point', coordinates },
    });

    sendResponse(res, 201, 'Pharmacy created', pharmacy);
  } catch (err) {
    next(err);
  }
};

const getMyPharmacy = async (req, res, next) => {
  try {
    const pharmacy = await Pharmacy.findOne({ user_id: req.user._id });
    if (!pharmacy) return next(new ApiError(404, 'Pharmacy not found'));
    sendResponse(res, 200, 'Pharmacy retrieved', pharmacy);
  } catch (err) {
    next(err);
  }
};

const updatePharmacy = async (req, res, next) => {
  try {
    const pharmacy = await Pharmacy.findOneAndUpdate(
      { user_id: req.user._id },
      req.body,
      { new: true, runValidators: true }
    );
    if (!pharmacy) return next(new ApiError(404, 'Pharmacy not found'));
    sendResponse(res, 200, 'Pharmacy updated', pharmacy);
  } catch (err) {
    next(err);
  }
};

const toggleOpen = async (req, res, next) => {
  try {
    const pharmacy = await Pharmacy.findOne({ user_id: req.user._id });
    if (!pharmacy) return next(new ApiError(404, 'Pharmacy not found'));
    pharmacy.is_open = !pharmacy.is_open;
    await pharmacy.save();
    sendResponse(res, 200, `Pharmacy is now ${pharmacy.is_open ? 'open' : 'closed'}`, pharmacy);
  } catch (err) {
    next(err);
  }
};

const _escapeRegex = (str) => str.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

const getNearbyPharmacies = async (req, res, next) => {
  try {
    const { lat, lng, radius = 5, insurance } = req.query;

    const filter = {
      ...buildNearbyQuery(parseFloat(lng), parseFloat(lat), parseFloat(radius)),
      is_verified: true,
    };

    if (insurance && insurance.trim()) {
      // Insurance search: all verified pharmacies (open or closed) with that insurance
      filter.accepted_insurances = {
        $elemMatch: { $regex: new RegExp(`^${_escapeRegex(insurance.trim())}$`, 'i') },
      };
    } else {
      filter.is_open = true;
    }

    const pharmacies = await Pharmacy.find(filter);

    const withDistance = pharmacies.map((p) => ({
      ...p.toObject(),
      distance_km: getDistanceKm(
        [parseFloat(lng), parseFloat(lat)],
        p.location.coordinates
      ),
    }));

    withDistance.sort((a, b) => a.distance_km - b.distance_km);

    sendResponse(res, 200, 'Nearby pharmacies retrieved', withDistance);
  } catch (err) {
    next(err);
  }
};

const getPharmacyById = async (req, res, next) => {
  try {
    const pharmacy = await Pharmacy.findById(req.params.id);
    if (!pharmacy) return next(new ApiError(404, 'Pharmacy not found'));
    sendResponse(res, 200, 'Pharmacy retrieved', pharmacy);
  } catch (err) {
    next(err);
  }
};

const getAllPharmacies = async (req, res, next) => {
  try {
    const { page = 1, limit = 20, verified } = req.query;
    const filter = {};
    if (verified !== undefined) filter.is_verified = verified === 'true';

    const [pharmacies, total] = await Promise.all([
      Pharmacy.find(filter)
        .skip((page - 1) * limit)
        .limit(parseInt(limit))
        .sort({ createdAt: -1 }),
      Pharmacy.countDocuments(filter),
    ]);

    sendResponse(res, 200, 'Pharmacies retrieved', {
      pharmacies, total, page: parseInt(page), pages: Math.ceil(total / limit),
    });
  } catch (err) {
    next(err);
  }
};

const verifyPharmacy = async (req, res, next) => {
  try {
    const pharmacy = await Pharmacy.findByIdAndUpdate(
      req.params.id,
      { is_verified: true },
      { new: true }
    );
    if (!pharmacy) return next(new ApiError(404, 'Pharmacy not found'));
    sendResponse(res, 200, 'Pharmacy verified', pharmacy);
  } catch (err) {
    next(err);
  }
};

module.exports = {
  createPharmacy, getMyPharmacy, getMyPharmacies, updatePharmacy, updatePharmacyById,
  toggleOpen, toggleOpenById,
  getNearbyPharmacies, getPharmacyById, getAllPharmacies, verifyPharmacy,
};