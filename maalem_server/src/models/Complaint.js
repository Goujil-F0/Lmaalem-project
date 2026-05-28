const pool = require('./db');

// Créer une réclamation
const createComplaint = async (booking_id, client_id, artisan_id, description) => {
  const result = await pool.query(
    `INSERT INTO complaints (booking_id, client_id, artisan_id, description, status)
     VALUES ($1, $2, $3, $4, 'open')
     RETURNING *`,
    [booking_id, client_id, artisan_id, description]
  );
  return result.rows[0];
};

// Récupérer toutes les réclamations
const getAllComplaints = async () => {
  const result = await pool.query(
    `SELECT c.*, u1.full_name as reporter_name, u2.full_name as target_name 
     FROM complaints c
     JOIN users u1 ON c.client_id = u1.id
     JOIN users u2 ON c.artisan_id = u2.id
     ORDER BY c.id DESC`
  );
  return result.rows;
};

module.exports = { createComplaint, getAllComplaints };
