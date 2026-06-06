const multer = require('multer');
const { CloudinaryStorage } = require('multer-storage-cloudinary');
const cloudinary = require('cloudinary').v2;

const chatStorage = new CloudinaryStorage({
  cloudinary,
  params: {
    folder:          'rapidsave/chat',
    allowed_formats: ['jpg', 'jpeg', 'png', 'webp'],
    transformation:  [{ width: 1200, crop: 'limit', quality: 'auto' }],
  },
});

const prescriptionStorage = new CloudinaryStorage({
  cloudinary,
  params: {
    folder:          'rapidsave/prescriptions',
    allowed_formats: ['jpg', 'jpeg', 'png', 'webp', 'pdf'],
    transformation:  [{ width: 2000, crop: 'limit', quality: 'auto' }],
  },
});

const paymentStorage = new CloudinaryStorage({
  cloudinary,
  params: {
    folder:          'rapidsave/payments',
    allowed_formats: ['jpg', 'jpeg', 'png', 'webp', 'pdf'],
    transformation:  [{ width: 2000, crop: 'limit', quality: 'auto' }],
  },
});

const fileFilter = (req, file, cb) => {
  const allowed = ['image/jpeg', 'image/jpg', 'image/png', 'image/webp', 'application/pdf'];
  allowed.includes(file.mimetype) ? cb(null, true) : cb(new Error('Unsupported file type'), false);
};

const uploadChatImage     = multer({ storage: chatStorage,        fileFilter, limits: { fileSize: 5  * 1024 * 1024 } }).single('image');
const uploadPrescriptions = multer({ storage: prescriptionStorage, fileFilter, limits: { fileSize: 10 * 1024 * 1024 } }).array('prescription_images', 5);
const uploadPaymentProof  = multer({ storage: paymentStorage,      fileFilter, limits: { fileSize: 10 * 1024 * 1024 } }).single('payment_proof');

module.exports = { uploadChatImage, uploadPrescriptions, uploadPaymentProof };