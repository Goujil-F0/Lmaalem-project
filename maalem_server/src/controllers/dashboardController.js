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
        COUNT(*) FILTER (WHERE status = 'accepted') as confirmed_bookings,
        COUNT(*) FILTER (WHERE status IN ('cancelled', 'rejected')) as cancelled_bookings,
        COALESCE(SUM(agreed_price) FILTER (WHERE status IN ('completed', 'paid_cash')), 0) as completed_revenue,
        COALESCE(SUM((agreed_price * commission_pct) / 100) FILTER (WHERE status IN ('completed', 'paid_cash')), 0) as paid_commission,
        COALESCE(SUM((agreed_price * commission_pct) / 100) FILTER (WHERE status IN ('pending', 'accepted')), 0) as expected_commission
       FROM bookings
       WHERE artisan_id = $1`,
      [artisanId]
    );

    const walletQuery = await pool.query(
      `SELECT id, balance
       FROM wallets
       WHERE user_id = $1`,
      [artisanId]
    );

    const walletId = walletQuery.rows[0]?.id;
    const transactionsQuery = walletId
      ? await pool.query(
          `SELECT amount, type, description, created_at
           FROM transactions
           WHERE wallet_id = $1
           ORDER BY created_at DESC
           LIMIT 5`,
          [walletId]
        )
      : { rows: [] };

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

    const upcomingBookingsQuery = await pool.query(
      `SELECT b.id, b.booking_date, b.status, b.description, b.agreed_price,
        b.created_at, u.full_name as client_name, u.phone as client_phone
       FROM bookings b
       JOIN users u ON b.client_id = u.id
       WHERE b.artisan_id = $1
         AND b.status IN ('pending', 'accepted')
       ORDER BY
         CASE WHEN b.status = 'accepted' THEN 0 ELSE 1 END,
         b.booking_date ASC
       LIMIT 8`,
      [artisanId]
    );

    const profileQuery = await pool.query(
      `SELECT u.id,
              u.full_name,
              u.email,
              u.phone,
              u.city,
              COALESCE(s.name, 'Artisan general') AS speciality,
              ap.description AS bio,
              ap.hourly_rate,
              COALESCE(ap.is_available, true) AS is_available,
              ap.profile_photo_url AS profile_image,
              COALESCE(ap.portfolio_images, ARRAY[]::TEXT[]) AS portfolio_images
       FROM users u
       LEFT JOIN artisan_profiles ap ON ap.user_id = u.id
       LEFT JOIN specialties s ON s.id = ap.specialty_id
       WHERE u.id = $1 AND u.role = 'artisan'`,
      [artisanId]
    );

    res.status(200).json({
      averageRating,
      totalReviews,
      artisanProfile: profileQuery.rows[0] || null,
      recentReviews: recentReviewsQuery.rows,
      pendingBookings: parseInt(bookingStatsQuery.rows[0].pending_bookings || 0),
      confirmedBookings: parseInt(bookingStatsQuery.rows[0].confirmed_bookings || 0),
      cancelledBookings: parseInt(bookingStatsQuery.rows[0].cancelled_bookings || 0),
      wallet: {
        balance: parseFloat(walletQuery.rows[0]?.balance || 0),
        grossCash: parseFloat(bookingStatsQuery.rows[0].completed_revenue || 0),
        commissionDebited: parseFloat(bookingStatsQuery.rows[0].paid_commission || 0),
        expectedCommission: parseFloat(bookingStatsQuery.rows[0].expected_commission || 0),
        canAcceptBookings: parseFloat(walletQuery.rows[0]?.balance || 0) > 0,
        recentTransactions: transactionsQuery.rows,
      },
      recentBookings: recentBookingsQuery.rows,
      upcomingBookings: upcomingBookingsQuery.rows,
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
        (SELECT COUNT(*) FROM complaints WHERE status IN ('open', 'in_progress')) as open_complaints,
        (SELECT COUNT(*) FROM complaints WHERE status = 'resolved') as resolved_complaints,
        (SELECT ROUND(AVG(rating)::NUMERIC, 1) FROM reviews) as platform_average_rating
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
      resolvedComplaints: parseInt(counts.rows[0].resolved_complaints),
      platformAverageRating: parseFloat(counts.rows[0].platform_average_rating || 0),
      topArtisans: topArtisans.rows,
    });
  } catch (error) {
    res.status(500).json({ message: 'Erreur serveur', error: error.message });
  }
};

const rechargeArtisanWallet = async (req, res) => {
  try {
    const artisanId = parseInt(req.params.id, 10);
    const amount = parseFloat(req.body.amount);

    if (!amount || amount <= 0) {
      return res.status(400).json({ message: 'Montant de recharge invalide.' });
    }

    if (req.user.role !== 'admin' && req.user.id !== artisanId) {
      return res.status(403).json({ message: 'Action non autorisée.' });
    }

    const walletQuery = await pool.query(
      `INSERT INTO wallets (user_id, balance)
       VALUES ($1, 0)
       ON CONFLICT (user_id) DO UPDATE SET user_id = EXCLUDED.user_id
       RETURNING id, balance`,
      [artisanId]
    );

    const wallet = walletQuery.rows[0];
    const updatedWallet = await pool.query(
      `UPDATE wallets
       SET balance = balance + $1, updated_at = CURRENT_TIMESTAMP
       WHERE id = $2
       RETURNING balance`,
      [amount, wallet.id]
    );

    await pool.query(
      `INSERT INTO transactions (wallet_id, amount, type, description)
       VALUES ($1, $2, 'recharge', $3)`,
      [wallet.id, amount, `Recharge wallet artisan #${artisanId}`]
    );

    res.status(200).json({
      message: 'Wallet recharge avec succes.',
      balance: parseFloat(updatedWallet.rows[0].balance || 0),
    });
  } catch (error) {
    res.status(500).json({ message: 'Erreur serveur', error: error.message });
  }
};

module.exports = { getArtisanDashboard, getAdminDashboard, rechargeArtisanWallet };
