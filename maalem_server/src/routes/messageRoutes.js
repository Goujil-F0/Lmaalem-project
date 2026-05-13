// routes/messageRoutes.js
const express = require('express');
const router = express.Router();
const { getChatHistory } = require('../controllers/messageController');

// Route: GET /api/messages/:bookingId
router.get('/:bookingId', getChatHistory);

module.exports = router;