const express = require('express');
const router = express.Router();
const { createComplaint, getComplaints, resolveComplaint } = require('../controllers/complaintController');
const { verifyToken, verifyClient } = require('../middleware/authMiddleware');
const adminMiddleware = require('../middleware/adminMiddleware');
const { body } = require('express-validator');

// POST /api/complaints — client
router.post(
  '/',
  verifyToken,
  verifyClient,
  [
    body('booking_id').isInt({ min: 1 }).withMessage('booking_id invalide'),
    body('artisan_id').isInt({ min: 1 }).withMessage('artisan_id invalide'),
    body('description').notEmpty().withMessage('description requise').isLength({ max: 1000 }),
  ],
  createComplaint
);

// GET /api/complaints — admin seulement
router.get('/', verifyToken, adminMiddleware, getComplaints);

// PUT /api/complaints/:id/resolve — admin seulement
router.put('/:id/resolve', verifyToken, adminMiddleware, resolveComplaint);

module.exports = router;
