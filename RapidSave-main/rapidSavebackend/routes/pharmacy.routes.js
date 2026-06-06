const express  = require('express');
const { body, query } = require('express-validator');
const {
  createPharmacy, getMyPharmacy, getMyPharmacies, updatePharmacy, updatePharmacyById,
  getNearbyPharmacies, getPharmacyById, toggleOpen, toggleOpenById,
  getAllPharmacies, verifyPharmacy,
} = require('../controllers/pharmacy.controller');
const { protect, pharmacyAdminOnly, adminOnly } = require('../middleware/auth.middleware');
const validate = require('../middleware/validate.middleware');

const router = express.Router();

router.get(
  '/nearby',
  protect,
  [
    query('lat').isFloat().withMessage('lat is required'),
    query('lng').isFloat().withMessage('lng is required'),
    query('radius').optional().isFloat({ min: 0.1, max: 50 }).withMessage('Radius must be between 0.1 and 50 km'),
    query('insurance').optional().isString().withMessage('insurance must be a string'),
  ],
  validate,
  getNearbyPharmacies
);

router.get('/',         protect, adminOnly, getAllPharmacies);
router.get('/me',       protect, pharmacyAdminOnly, getMyPharmacy);
router.get('/mine',     protect, pharmacyAdminOnly, getMyPharmacies);
router.get('/:id',      protect, getPharmacyById);

router.post(
  '/',
  protect,
  pharmacyAdminOnly,
  [
    body('name').trim().notEmpty().withMessage('Name is required'),
    body('license_number').trim().notEmpty().withMessage('License number is required'),
    body('address').trim().notEmpty().withMessage('Address is required'),
    body('coordinates').isArray({ min: 2, max: 2 }).withMessage('coordinates must be [lng, lat]'),
    body('phone').optional().isMobilePhone(),
    body('accepted_insurances').optional().isArray(),
    body('accepted_insurances.*').optional().isString().trim().notEmpty(),
  ],
  validate,
  createPharmacy
);

router.patch(
  '/me',
  protect,
  pharmacyAdminOnly,
  [
    body('name').optional().trim().notEmpty(),
    body('address').optional().trim().notEmpty(),
    body('phone').optional().isMobilePhone(),
    body('accepted_insurances').optional().isArray(),
    body('accepted_insurances.*').optional().isString().trim().notEmpty(),
  ],
  validate,
  updatePharmacy
);

router.patch('/me/toggle-open',  protect, pharmacyAdminOnly, toggleOpen);
router.patch('/:id/open',        protect, pharmacyAdminOnly, toggleOpenById);
router.patch(
  '/:id',
  protect,
  pharmacyAdminOnly,
  [
    body('name').optional().trim().notEmpty(),
    body('address').optional().trim().notEmpty(),
    body('phone').optional().isMobilePhone(),
    body('accepted_insurances').optional().isArray(),
    body('accepted_insurances.*').optional().isString().trim().notEmpty(),
  ],
  validate,
  updatePharmacyById,
);
router.patch('/:id/verify',      protect, adminOnly, verifyPharmacy);

module.exports = router;