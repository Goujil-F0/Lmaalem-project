const pool = require('./db');

// Créer un avis
const createReview = async (booking_id, client_id, artisan_id, rating, comment) => {
  const result = await pool.query(
    `INSERT INTO reviews (booking_id, client_id, artisan_id, rating, comment)
     VALUES ($1, $2, $3, $4, $5)
     RETURNING *`,
    [booking_id, client_id, artisan_id, rating, comment]
  );
  return result.rows[0];
};

// Récupérer les avis d'un artisan (avec le nom du client)
const findByArtisan = async (artisan_id) => {
  const result = await pool.query(
    `SELECT r.*, u.full_name as client_name 
     FROM reviews r
     JOIN users u ON r.client_id = u.id
     WHERE r.artisan_id = $1
     ORDER BY r.created_at DESC`,
    [artisan_id]
  );
  return result.rows;
};

// Calculer la moyenne
const getAverage = async (artisan_id) => {
  const result = await pool.query(
    `SELECT AVG(rating) as average, COUNT(*) as count 
     FROM reviews 
     WHERE artisan_id = $1`,
    [artisan_id]
  );
  return result.rows[0];
};

module.exports = { createReview, findByArtisan, getAverage };