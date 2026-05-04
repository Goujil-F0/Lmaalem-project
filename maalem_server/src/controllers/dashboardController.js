const pool = require('../models/db'); // On utilise la connexion PostgreSQL

// GET /api/dashboard/artisan/:id — Stats pour un artisan
const getArtisanDashboard = async (req, res) => {
  try {
    const artisanId = req.params.id;

    // 1. Note moyenne et total d'avis
    const statsQuery = await pool.query(
      "SELECT AVG(rating) as avg_rating, COUNT(*) as total_reviews FROM reviews WHERE artisan_id = $1",
      [artisanId]
    );
    
    const averageRating = Math.round(parseFloat(statsQuery.rows[0].avg_rating || 0) * 10) / 10;
    const totalReviews = parseInt(statsQuery.rows[0].total_reviews);

    // 2. Les 5 derniers avis avec le nom du client
    const recentReviewsQuery = await pool.query(
      `SELECT r.*, u.full_name as client_name 
       FROM reviews r 
       JOIN users u ON r.client_id = u.id 
       WHERE r.artisan_id = $1 
       ORDER BY r.created_at DESC LIMIT 5`,
      [artisanId]
    );

    res.status(200).json({
      averageRating,
      totalReviews,
      recentReviews: recentReviewsQuery.rows,
    });
  } catch (error) {
    res.status(500).json({ message: 'Erreur serveur', error: error.message });
  }
};

// GET /api/dashboard/admin — Stats globales pour l'admin
const getAdminDashboard = async (req, res) => {
  try {
    // 1. Comptages globaux
    const counts = await pool.query(`
      SELECT 
        (SELECT COUNT(*) FROM reviews) as total_reviews,
        (SELECT COUNT(*) FROM complaints) as total_complaints,
        (SELECT COUNT(*) FROM complaints WHERE status = 'open') as open_complaints
    `);

    // 2. Top 5 des artisans par note
    const topArtisans = await pool.query(`
      SELECT u.full_name, AVG(r.rating) as average, COUNT(r.id) as review_count
      FROM reviews r
      JOIN users u ON r.artisan_id = u.id
      GROUP BY u.full_name, r.artisan_id
      ORDER BY average DESC
      LIMIT 5
    `);

    res.status(200).json({
      totalReviews: parseInt(counts.rows[0].total_reviews),
      totalComplaints: parseInt(counts.rows[0].total_complaints),
      openComplaints: parseInt(counts.rows[0].open_complaints),
      topArtisans: topArtisans.rows,
    });
  } catch (error) {
    res.status(500).json({ message: 'Erreur serveur', error: error.message });
  }
};

module.exports = { getArtisanDashboard, getAdminDashboard };