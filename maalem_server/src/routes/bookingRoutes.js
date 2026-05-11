const express = require('express');
const router = express.Router();
const { createNewBooking, seedTestUsers, getBookingHistory } = require('../controllers/bookingController');

// Route de test
router.get('/seed', seedTestUsers);

// Route pour l'historique (GET /api/bookings/history/:userId/:role)
// Important : à placer AVANT les routes avec des ID dynamiques
router.get('/history/:userId/:role', getBookingHistory);

// Route pour créer (POST /api/bookings)
router.post('/', createNewBooking);

module.exports = router;