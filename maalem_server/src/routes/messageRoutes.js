const express = require('express');
const router = express.Router();
const { getChatHistory, sendMessage } = require('../controllers/messageController');

router.get('/:bookingId', getChatHistory);
router.post('/', sendMessage);

router.patch('/read/:bookingId/:userId', markMessagesRead);

module.exports = router;