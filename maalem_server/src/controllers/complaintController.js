const pool = require('../models/db');
const { validationResult } = require('express-validator');

const createComplaint = async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }

  try {
    const { booking_id, artisan_id, description } = req.body;
    const client_id = req.user.id;

    const booking = await pool.query(
      `SELECT id, status
       FROM bookings
       WHERE id = $1 AND client_id = $2 AND artisan_id = $3`,
      [booking_id, client_id, artisan_id]
    );

    if (booking.rows.length === 0) {
      return res.status(404).json({ message: 'Réservation introuvable pour ce client et cet artisan.' });
    }

    if (!['accepted', 'completed'].includes(booking.rows[0].status)) {
      return res.status(400).json({
        message: "Vous pouvez déposer une réclamation seulement après l'acceptation de l'artisan.",
      });
    }

    const result = await pool.query(
      `INSERT INTO complaints (booking_id, client_id, artisan_id, description)
       VALUES ($1, $2, $3, $4) RETURNING *`,
      [booking_id, client_id, artisan_id, description]
    );

    res.status(201).json(result.rows[0]);
  } catch (error) {
    res.status(500).json({ message: 'Erreur serveur', error: error.message });
  }
};

const getComplaints = async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT c.*, 
        u1.full_name as client_name, 
        u2.full_name as artisan_name,
        b.booking_date,
        b.status as booking_status,
        b.agreed_price
       FROM complaints c
       JOIN users u1 ON c.client_id = u1.id
       JOIN users u2 ON c.artisan_id = u2.id
       JOIN bookings b ON c.booking_id = b.id
       ORDER BY c.created_at DESC`
    );
    res.status(200).json(result.rows);
  } catch (error) {
    res.status(500).json({ message: 'Erreur serveur', error: error.message });
  }
};

const resolveComplaint = async (req, res) => {
  try {
    const result = await pool.query(
      `UPDATE complaints SET status = 'resolved' 
       WHERE id = $1 RETURNING *`,
      [req.params.id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ message: 'Réclamation introuvable.' });
    }

    res.status(200).json({ message: 'Réclamation résolue.', complaint: result.rows[0] });
  } catch (error) {
    res.status(500).json({ message: 'Erreur serveur', error: error.message });
  }
};

module.exports = { createComplaint, getComplaints, resolveComplaint };
