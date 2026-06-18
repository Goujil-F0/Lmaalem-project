const express = require('express');
const router = express.Router();
const {
  getChatHistory,
  sendMessage,
  markMessagesRead,
} = require('../controllers/messageController');

router.get('/:bookingId', getChatHistory);
router.post('/', sendMessage);

router.patch('/read/:bookingId/:userId', markMessagesRead);

module.exports = router;
