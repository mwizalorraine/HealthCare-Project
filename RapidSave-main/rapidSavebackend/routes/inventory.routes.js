const express  = require('express');
const { body } = require('express-validator');
const {
  upsertInventory, getPharmacyInventory,
  getMedicineAvailability, deleteInventoryItem,
} = require('../controllers/inventory.controller');
const { protect, pharmacyAdminOnly } = require('../middleware/auth.middleware');
const validate = require('../middleware/validate.middleware');

const router = express.Router();

router.use(protect);

router.get('/pharmacy/:pharmacyId',       getPharmacyInventory);
router.get('/medicine/:medicineId',       getMedicineAvailability);

router.post(
  '/',
  pharmacyAdminOnly,
  [
    body('medicine_id').isMongoId().withMessage('Valid medicine ID is required'),
    body('price').isFloat({ min: 0 }).withMessage('Price must be a positive number'),
    body('quantity').isInt({ min: 0 }).withMessage('Quantity must be a non-negative integer'),
    body('expiry_date').optional().isISO8601().withMessage('Invalid expiry date'),
  ],
  validate,
  upsertInventory
);

router.delete('/:id', pharmacyAdminOnly, deleteInventoryItem);

module.exports = router;