const ComplaintModel = require('../models/Complaint');
const pool = require('../models/db'); // Chemin corrigé : on va le chercher dans models
const { validationResult } = require('express-validator');

// POST /api/complaints — Déposer une réclamation
const createComplaint = async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) return res.status(400).json({ errors: errors.array() });

  try {
    const { bookingId, artisanId, description } = req.body;
    const clientId = req.user.id;

    const complaint = await ComplaintModel.createComplaint(bookingId, clientId, artisanId, description);
    res.status(201).json(complaint);
  } catch (error) {
    res.status(500).json({ message: 'Erreur serveur', error: error.message });
  }
};

// GET /api/complaints — Lister les réclamations (Admin)
const getComplaints = async (req, res) => {
  try {
    const complaints = await ComplaintModel.getAllComplaints();
    res.status(200).json(complaints);
  } catch (error) {
    res.status(500).json({ message: 'Erreur serveur', error: error.message });
  }
};

// PUT /api/complaints/:id/resolve — Résoudre une réclamation (Admin)
const resolveComplaint = async (req, res) => {
  try {
    const { id } = req.params;
    
    const result = await pool.query(
      "UPDATE complaints SET status = 'resolved' WHERE id = $1 RETURNING *",
      [id]
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