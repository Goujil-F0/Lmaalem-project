const ReviewModel = require('../models/Review');
const pool = require('../models/db');
const { validationResult } = require('express-validator');

const findClientBooking = async (bookingId, clientId, artisanId) => {
  const result = await pool.query(
    `SELECT id, status
     FROM bookings
     WHERE id = $1 AND client_id = $2 AND artisan_id = $3`,
    [bookingId, clientId, artisanId]
  );
  return result.rows[0];
};

const createReview = async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) return res.status(400).json({ errors: errors.array() });

  try {
    const { booking_id, artisan_id, rating, comment } = req.body;
    const client_id = req.user.id;
    const booking = await findClientBooking(booking_id, client_id, artisan_id);

    if (!booking) {
      return res.status(404).json({ message: 'Réservation introuvable pour ce client et cet artisan.' });
    }

    if (!['completed', 'paid_cash'].includes(booking.status)) {
      return res.status(400).json({ message: 'Un avis peut être laissé seulement après une réservation terminée.' });
    }

    const review = await ReviewModel.createReview(booking_id, client_id, artisan_id, rating, comment);
    res.status(201).json(review);
  } catch (error) {
    if (error.code === '23505') {
      return res.status(409).json({ message: 'Un avis existe déjà pour cette réservation.' });
    }
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
