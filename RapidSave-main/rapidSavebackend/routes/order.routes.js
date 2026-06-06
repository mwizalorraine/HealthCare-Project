const express  = require('express');
const { body } = require('express-validator');
const {
  createOrder, getMyOrders, getOrderById,
  updateOrderStatus, getPharmacyOrders,
  uploadPaymentProof, verifyPayment,
  getPendingPayments,
} = require('../controllers/order.controller');
const { protect, pharmacyAdminOnly, patientOnly } = require('../middleware/auth.middleware');
const { uploadPrescriptions, uploadPaymentProof: uploadProofMiddleware } = require('../middleware/upload.middleware');
const validate = require('../middleware/validate.middleware');

const router = express.Router();

router.use(protect);

router.get('/my',               patientOnly,       getMyOrders);
router.get('/pharmacy',         pharmacyAdminOnly, getPharmacyOrders);
router.get('/pending-payments', pharmacyAdminOnly, getPendingPayments);
router.get('/:id',              getOrderById);

router.post(
  '/',
  patientOnly,
  uploadPrescriptions,
  [
    body('pharmacy_id').isMongoId().withMessage('Valid pharmacy ID is required'),
    body('type').isIn(['reservation', 'delivery']).withMessage('Invalid order type'),
    body('items').isArray({ min: 1 }).withMessage('At least one item is required'),
    body('items.*.inventory_id').isMongoId().withMessage('Valid inventory ID required'),
    body('items.*.quantity').isInt({ min: 1 }).withMessage('Quantity must be at least 1'),
    body('notes').optional().isString(),
  ],
  validate,
  createOrder
);

router.patch(
  '/:id/status',
  pharmacyAdminOnly,
  [body('status').isIn(['confirmed', 'ready', 'completed', 'cancelled']).withMessage('Invalid status')],
  validate,
  updateOrderStatus
);

router.post(
  '/:id/payment-proof',
  patientOnly,
  uploadProofMiddleware,
  [
    body('provider').trim().notEmpty().withMessage('Payment provider is required'),
    body('reference').trim().notEmpty().withMessage('Payment reference is required'),
  ],
  validate,
  uploadPaymentProof
);

router.patch(
  '/:id/payment/verify',
  pharmacyAdminOnly,
  [
    body('action').isIn(['verify', 'reject']).withMessage('Action must be verify or reject'),
    body('rejected_reason').if(body('action').equals('reject')).trim().notEmpty().withMessage('Rejection reason is required'),
  ],
  validate,
  verifyPayment
);

module.exports = router;