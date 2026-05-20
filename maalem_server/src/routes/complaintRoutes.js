const express = require('express');
const router = express.Router();
const { createComplaint, getComplaints, resolveComplaint } = require('../controllers/complaintController');
const { verifyToken } = require('../middleware/authMiddleware');
const adminMiddleware = require('../middleware/adminMiddleware');
const { body } = require('express-validator');

// POST /api/complaints — client
router.post(
  '/',
  verifyToken,
  [
    body('booking_id').notEmpty().withMessage('booking_id requis'),
    body('artisan_id').notEmpty().withMessage('artisan_id requis'),
    body('description').notEmpty().withMessage('description requise').isLength({ max: 1000 }),
  ],
  createComplaint
);

// GET /api/complaints — admin seulement
router.get('/', verifyToken, adminMiddleware, getComplaints);

// PUT /api/complaints/:id/resolve — admin seulement
router.put('/:id/resolve', verifyToken, adminMiddleware, resolveComplaint);

module.exports = router;