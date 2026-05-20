const ReviewModel = require('../models/Review');
const { validationResult } = require('express-validator');

const createReview = async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) return res.status(400).json({ errors: errors.array() });

  try {
    const { booking_id, artisan_id, rating, comment } = req.body;
    const client_id = req.user.id;

    const review = await ReviewModel.createReview(booking_id, client_id, artisan_id, rating, comment);
    res.status(201).json(review);
  } catch (error) {
    res.status(500).json({ message: 'Erreur serveur', error: error.message });
  }
};

const getArtisanReviews = async (req, res) => {
  try {
    const reviews = await ReviewModel.findByArtisan(req.params.artisanId);
    res.status(200).json(reviews);
  } catch (error) {
    res.status(500).json({ message: 'Erreur serveur', error: error.message });
  }
};

const getAverageRating = async (req, res) => {
  try {
    const stats = await ReviewModel.getAverage(req.params.artisanId);
    res.status(200).json({
      average: Math.round(parseFloat(stats.average || 0) * 10) / 10,
      count: parseInt(stats.count)
    });
  } catch (error) {
    res.status(500).json({ message: 'Erreur serveur', error: error.message });
  }
};

module.exports = { createReview, getArtisanReviews, getAverageRating };