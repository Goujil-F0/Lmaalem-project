const express = require('express');
const router = express.Router();
const { getArtisanDashboard, getAdminDashboard } = require('../controllers/dashboardController');
const authMiddleware = require('../middleware/authMiddleware');
const adminMiddleware = require('../middleware/adminMiddleware');

// GET /api/dashboard/artisan/:id — artisan connecté
router.get('/artisan/:id',authMiddleware, getArtisanDashboard);

// GET /api/dashboard/admin — admin seulement
router.get('/admin',authMiddleware, getAdminDashboard);

module.exports = router;