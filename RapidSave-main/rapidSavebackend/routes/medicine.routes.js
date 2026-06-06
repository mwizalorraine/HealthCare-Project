const express  = require('express');
const { body, query } = require('express-validator');
const {
  createMedicine, getAllMedicines,
  getMedicineById, updateMedicine, searchMedicines,
} = require('../controllers/medicine.controller');
const { protect, adminOnly } = require('../middleware/auth.middleware');
const validate = require('../middleware/validate.middleware');

const router = express.Router();

router.use(protect);

router.get(
  '/search',
  [query('q').trim().notEmpty().withMessage('Search query is required')],
  validate,
  searchMedicines
);

router.get('/',    getAllMedicines);
router.get('/:id', getMedicineById);

router.post(
  '/',
  adminOnly,
  [
    body('name').trim().notEmpty().withMessage('Name is required'),
    body('unit').trim().notEmpty().withMessage('Unit is required'),
  ],
  validate,
  createMedicine
);

router.patch('/:id', adminOnly, updateMedicine);

module.exports = router;