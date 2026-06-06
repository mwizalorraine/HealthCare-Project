const express  = require('express');
const { body, param } = require('express-validator');
const {
  getConversation, getMessages,
  sendMessage, addReaction, markRead,
  getConversationByOrder, getOrCreateConversation,
} = require('../controllers/conversation.controller');
const { protect } = require('../middleware/auth.middleware');
const { uploadChatImage } = require('../middleware/upload.middleware');
const validate = require('../middleware/validate.middleware');

const router = express.Router();

router.use(protect);

router.post('/',                 getOrCreateConversation);  // create or find by order_id
router.get('/by-order/:orderId', getConversationByOrder);   // must be before /:id
router.get('/:id',               getConversation);
router.get('/:id/messages',      getMessages);

router.post(
  '/:id/messages',
  uploadChatImage,
  [
    param('id').isMongoId().withMessage('Valid conversation ID is required'),
    body('message_type').isIn(['text', 'image', 'system']).withMessage('Invalid message type'),
    body('content').if(body('message_type').equals('text')).trim().notEmpty().withMessage('Content is required for text messages'),
    body('reply_to').optional().isMongoId().withMessage('Invalid reply message ID'),
  ],
  validate,
  sendMessage
);

router.post(
  '/:id/messages/:messageId/reactions',
  [
    param('messageId').isMongoId().withMessage('Valid message ID is required'),
    body('emoji').trim().notEmpty().withMessage('Emoji is required'),
  ],
  validate,
  addReaction
);

router.patch('/:id/messages/read', markRead);

module.exports = router;