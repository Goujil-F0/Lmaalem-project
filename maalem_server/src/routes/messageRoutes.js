// routes/messageRoutes.js
const express = require('express');
const router = express.Router();
const { getChatHistory, markMessagesRead } = require('../controllers/messageController');

// Route: GET /api/messages/:bookingId
router.get('/:bookingId', getChatHistory);

router.patch('/read/:bookingId/:userId', markMessagesRead);

module.exports = router;