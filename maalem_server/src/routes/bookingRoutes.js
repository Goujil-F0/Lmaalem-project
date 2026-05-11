// backend/routes/bookingRoutes.js
const express = require('express');
const router = express.Router();
const { createNewBooking, seedTestUsers } = require('../controllers/bookingController');

// Route temporaire pour créer nos faux utilisateurs (GET)
router.get('/seed', seedTestUsers);

// Route pour créer une réservation (POST /api/bookings)
router.post('/', createNewBooking);

module.exports = router;