// routes/artisanRoutes.js
const express = require('express');
const router = express.Router();
const { getAllArtisans } = require('../controllers/artisanController');

// GET /api/artisans
router.get('/artisans', getAllArtisans);

module.exports = router;