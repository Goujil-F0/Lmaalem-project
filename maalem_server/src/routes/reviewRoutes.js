const express = require('express');
const router = express.Router();
const { createReview, getArtisanReviews, getAverageRating } = require('../controllers/reviewController');
const { verifyToken } = require('../middleware/authMiddleware');
const { body } = require('express-validator');

// POST /api/reviews
router.post(
  '/',
  verifyToken,
  [
    body('booking_id').notEmpty().withMessage('booking_id requis'),
    body('artisan_id').notEmpty().withMessage('artisan_id requis'),
    body('rating').isInt({ min: 1, max: 5 }).withMessage('Note entre 1 et 5'),
    body('comment').optional().isLength({ max: 500 }),
  ],
  createReview
);

// GET /api/reviews/:artisanId
router.get('/:artisanId', verifyToken, getArtisanReviews);

// GET /api/reviews/:artisanId/average
router.get('/:artisanId/average', verifyToken, getAverageRating);

module.exports = router;