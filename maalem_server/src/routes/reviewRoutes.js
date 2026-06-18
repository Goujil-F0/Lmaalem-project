const express = require('express');
const router = express.Router();
const { createReview, getArtisanReviews, getAverageRating } = require('../controllers/reviewController');
const { verifyToken, verifyClient } = require('../middleware/authMiddleware');
const { body } = require('express-validator');

// POST /api/reviews
router.post(
  '/',
  verifyToken,
  verifyClient,
  [
    body('booking_id').isInt({ min: 1 }).withMessage('booking_id invalide'),
    body('artisan_id').isInt({ min: 1 }).withMessage('artisan_id invalide'),
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
