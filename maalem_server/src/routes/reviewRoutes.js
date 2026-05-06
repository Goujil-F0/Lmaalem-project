const express = require('express');
const router = express.Router();
const { createReview, getArtisanReviews, getAverageRating } = require('../controllers/reviewController');
const authMiddleware = require('../middleware/authMiddleware');
const { body } = require('express-validator');

// POST /api/reviews
router.post(
  '/',
  authMiddleware,
  [
    body('bookingId').notEmpty().withMessage('bookingId requis'),
    body('artisanId').notEmpty().withMessage('artisanId requis'),
    body('rating').isInt({ min: 1, max: 5 }).withMessage('Note entre 1 et 5'),
    body('comment').optional().isLength({ max: 500 }),
  ],
  createReview
);

// GET /api/reviews/:artisanId
router.get('/:artisanId',authMiddleware, getArtisanReviews);

// GET /api/reviews/:artisanId/average
router.get('/:artisanId/average', authMiddleware, getAverageRating);

module.exports = router;