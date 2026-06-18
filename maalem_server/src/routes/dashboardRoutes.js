const express = require('express');
const router = express.Router();
const { getArtisanDashboard, getAdminDashboard, rechargeArtisanWallet } = require('../controllers/dashboardController');
const { verifyToken } = require('../middleware/authMiddleware');
const adminMiddleware = require('../middleware/adminMiddleware');

// GET /api/dashboard/artisan/:id
router.get('/artisan/:id', verifyToken, getArtisanDashboard);

// POST /api/dashboard/artisan/:id/wallet/recharge
router.post('/artisan/:id/wallet/recharge', verifyToken, rechargeArtisanWallet);

// GET /api/dashboard/admin — admin seulement
router.get('/admin', verifyToken, adminMiddleware, getAdminDashboard);

module.exports = router;
