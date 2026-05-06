const express = require('express');
const router = express.Router();
const { createComplaint, getComplaints, resolveComplaint } = require('../controllers/complaintController');
const authMiddleware = require('../middleware/authMiddleware');
const adminMiddleware = require('../middleware/adminMiddleware');
const { body } = require('express-validator');

// POST /api/complaints — client
router.post(
  '/',
  authMiddleware,
  [
    body('targetId').notEmpty().withMessage('targetId requis'),
    body('description').notEmpty().withMessage('description requise').isLength({ max: 1000 }),
  ],
  createComplaint
);

// GET /api/complaints — admin seulement
router.get('/',authMiddleware,adminMiddleware, getComplaints);

// PUT /api/complaints/:id/resolve — admin seulement
router.put('/:id/resolve', authMiddleware, adminMiddleware, resolveComplaint);

module.exports = router;