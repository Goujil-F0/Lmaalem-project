const pool = require('../models/db');

const getArtisanDashboard = async (req, res) => {
  try {
    const artisanId = req.params.id;

    const statsQuery = await pool.query(
      `SELECT AVG(rating) as avg_rating, COUNT(*) as total_reviews 
       FROM reviews WHERE artisan_id = $1`,
      [artisanId]
    );

    const averageRating = Math.round(parseFloat(statsQuery.rows[0].avg_rating || 0) * 10) / 10;
    const totalReviews = parseInt(statsQuery.rows[0].total_reviews);

    const bookingStatsQuery = await pool.query(
      `SELECT
        COUNT(*) FILTER (WHERE status = 'pending') as pending_bookings,
        COUNT(*) FILTER (WHERE status = 'accepted') as confirmed_bookings
       FROM bookings
       WHERE artisan_id = $1`,
      [artisanId]
    );

    const recentReviewsQuery = await pool.query(
      `SELECT r.*, u.full_name as client_name 
       FROM reviews r 
       JOIN users u ON r.client_id = u.id 
       WHERE r.artisan_id = $1 
       ORDER BY r.created_at DESC LIMIT 5`,
      [artisanId]
    );

    const recentBookingsQuery = await pool.query(
      `SELECT b.id, b.booking_date, b.status, b.description, b.agreed_price,
        b.created_at, u.full_name as client_name, u.phone as client_phone
       FROM bookings b
       JOIN users u ON b.client_id = u.id
       WHERE b.artisan_id = $1
       ORDER BY b.created_at DESC
       LIMIT 5`,
      [artisanId]
    );

    res.status(200).json({
      averageRating,
      totalReviews,
      recentReviews: recentReviewsQuery.rows,
      pendingBookings: parseInt(bookingStatsQuery.rows[0].pending_bookings || 0),
      confirmedBookings: parseInt(bookingStatsQuery.rows[0].confirmed_bookings || 0),
      recentBookings: recentBookingsQuery.rows,
    });
  } catch (error) {
    res.status(500).json({ message: 'Erreur serveur', error: error.message });
  }
};

const getAdminDashboard = async (req, res) => {
  try {
    const counts = await pool.query(`
      SELECT 
        (SELECT COUNT(*) FROM reviews) as total_reviews,
        (SELECT COUNT(*) FROM complaints) as total_complaints,
        (SELECT COUNT(*) FROM complaints WHERE status IN ('open', 'in_progress')) as open_complaints
    `);

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
