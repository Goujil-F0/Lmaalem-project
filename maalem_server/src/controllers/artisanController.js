// controllers/artisanController.js
const pool = require('../models/db'); // ta connexion PostgreSQL

const getAllArtisans = async (req, res) => {
  try {
    // En prod : remplace les mockData par une vraie requête SQL
    // const result = await pool.query(`
    //   SELECT u.id, u.full_name, u.phone, u.city, u.latitude, u.longitude,
    //          ap.specialty_id, ap.description, ap.hourly_rate,
    //          ap.is_available, ap.average_rating
    //   FROM users u
    //   JOIN artisan_profiles ap ON ap.user_id = u.id
    //   WHERE u.role = 'artisan'
    // `);
    // return res.json(result.rows);

    const mockArtisans = [
      {
        id: 1,
        full_name: "Hassan Benali",
        phone: "0661234567",
        city: "Casablanca",
        latitude: 33.5731,
        longitude: -7.5898,
        specialty_id: 1,
        description: "Expert en plomberie, 10 ans d'expérience",
        hourly_rate: 150.00,
        is_available: true,
        average_rating: 4.8,
      },
      {
        id: 2,
        full_name: "Fatima Zahra",
        phone: "0662345678",
        city: "Casablanca",
        latitude: 33.5800,
        longitude: -7.6200,
        specialty_id: 8,
        description: "Électricienne certifiée",
        hourly_rate: 120.00,
        is_available: true,
        average_rating: 4.5,
      },
    ];

    return res.status(200).json(mockArtisans);
  } catch (err) {
    console.error('[ArtisanController] Erreur getAllArtisans:', err);
    return res.status(500).json({ error: 'Erreur serveur interne.' });
  }
};

module.exports = { getAllArtisans };