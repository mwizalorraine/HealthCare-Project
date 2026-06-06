const express  = require('express');
const { body } = require('express-validator');
const {
  createDelivery, getDeliveryById, getDeliveryByOrder,
  updateDeliveryStatus, getMyDeliveries,
} = require('../controllers/delivery.controller');
const { protect, pharmacyAdminOnly, patientOnly } = require('../middleware/auth.middleware');
const validate = require('../middleware/validate.middleware');

const router = express.Router();

router.use(protect);

router.get('/my',             patientOnly, getMyDeliveries);
router.get('/order/:orderId',              getDeliveryByOrder);
router.get('/:id',                         getDeliveryById);

router.post(
  '/',
  pharmacyAdminOnly,
  [
    body('order_id').isMongoId().withMessage('Valid order ID is required'),
    body('address').trim().notEmpty().withMessage('Address is required'),
    body('coordinates').isArray({ min: 2, max: 2 }).withMessage('coordinates must be [lng, lat]'),
    body('rider_name').optional().trim().notEmpty(),
    body('rider_phone').optional().isMobilePhone(),
    body('estimated_at').optional().isISO8601(),
  ],
  validate,
  createDelivery
);

router.patch(
  '/:id/status',
  pharmacyAdminOnly,
  [body('status').isIn(['assigned', 'in_transit', 'delivered', 'failed']).withMessage('Invalid status')],
  validate,
  updateDeliveryStatus
);

module.exports = router;