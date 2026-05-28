// controllers/artisanController.js
const pool = require('../models/db'); // ta connexion PostgreSQL

const getAllArtisans = async (req, res) => {
  try {
    let result;

    try {
      result = await pool.query(`
        SELECT u.id, u.full_name, u.email, u.phone, u.city, u.latitude, u.longitude,
          s.name as speciality, ap.description, ap.hourly_rate,
          ap.is_available, ap.profile_photo_url, ap.portfolio_images,
          COALESCE(ROUND(AVG(r.rating)::NUMERIC, 1), ap.average_rating, 0) as average_rating,
          COUNT(r.id) as review_count
        FROM users u
        JOIN artisan_profiles ap ON ap.user_id = u.id
        LEFT JOIN specialties s ON ap.specialty_id = s.id
        LEFT JOIN reviews r ON r.artisan_id = u.id
        WHERE u.role = 'artisan'
        GROUP BY u.id, s.name, ap.user_id
        ORDER BY u.full_name
      `);
    } catch (error) {
      if (error.code !== '42703') throw error;

      result = await pool.query(`
        SELECT u.id, u.full_name, u.email, u.phone, u.city, u.latitude, u.longitude,
          s.name as speciality, ap.description, ap.hourly_rate,
          ap.is_available, ap.profile_photo_url, ARRAY[]::TEXT[] as portfolio_images,
          COALESCE(ROUND(AVG(r.rating)::NUMERIC, 1), ap.average_rating, 0) as average_rating,
          COUNT(r.id) as review_count
        FROM users u
        JOIN artisan_profiles ap ON ap.user_id = u.id
        LEFT JOIN specialties s ON ap.specialty_id = s.id
        LEFT JOIN reviews r ON r.artisan_id = u.id
        WHERE u.role = 'artisan'
        GROUP BY u.id, s.name, ap.user_id
        ORDER BY u.full_name
      `);
    }

    if (result.rows.length > 0) {
      return res.status(200).json(result.rows);
    }

    const mockArtisans = [
      // Plomberie
      {
        id: 1,
        full_name: "Hassan Benali",
        phone: "0661234567",
        city: "Casablanca",
        latitude: 33.5731,
        longitude: -7.5898,
        speciality: "Plomberie",
        description: "Expert en plomberie, 10 ans d'expérience",
        hourly_rate: 150.00,
        is_available: true,
        average_rating: 4.8,
        review_count: 0,
        portfolio_images: [],
      },
      // Électricité
      {
        id: 2,
        full_name: "Fatima Zahra",
        phone: "0662345678",
        city: "Casablanca",
        latitude: 33.5800,
        longitude: -7.6200,
        speciality: "Électricité",
        description: "Électricienne certifiée, 8 ans d'expérience",
        hourly_rate: 120.00,
        is_available: true,
        average_rating: 4.5,
        review_count: 0,
        portfolio_images: [],
      },
      // Maçonnerie
      {
        id: 3,
        full_name: "Ahmed Makni",
        phone: "0663456789",
        city: "Marrakech",
        latitude: 31.6295,
        longitude: -8.0089,
        speciality: "Maçonnerie",
        description: "Maçon expert, travaux de qualité supérieure",
        hourly_rate: 130.00,
        is_available: true,
        average_rating: 4.7,
        review_count: 0,
        portfolio_images: [],
      },
      // Peinture
      {
        id: 4,
        full_name: "Karim Bouhassoun",
        phone: "0664567891",
        city: "Rabat",
        latitude: 34.0209,
        longitude: -6.8416,
        speciality: "Peinture",
        description: "Peintre professionnel - finitions impeccables",
        hourly_rate: 100.00,
        is_available: true,
        average_rating: 4.6,
      },
      // Carrelage
      {
        id: 5,
        full_name: "Mohammed El Kadi",
        phone: "0665678912",
        city: "Fez",
        latitude: 34.0333,
        longitude: -5.0033,
        speciality: "Carrelage",
        description: "Carreleur avec 15 ans d'expérience",
        hourly_rate: 140.00,
        is_available: true,
        average_rating: 4.9,
      },
      // Menuiserie
      {
        id: 6,
        full_name: "Sofia Bennani",
        phone: "0666789123",
        city: "Tangier",
        latitude: 35.7667,
        longitude: -5.8167,
        speciality: "Menuiserie",
        description: "Menuisier expert en bois massif",
        hourly_rate: 135.00,
        is_available: true,
        average_rating: 4.8,
      },
      // Climatisation
      {
        id: 7,
        full_name: "Rachid Amezian",
        phone: "0667891234",
        city: "Agadir",
        latitude: 30.4278,
        longitude: -9.5981,
        speciality: "Climatisation",
        description: "Installation et maintenance climatisation",
        hourly_rate: 125.00,
        is_available: true,
        average_rating: 4.4,
      },
      // Serrurerie
      {
        id: 8,
        full_name: "Noureddine Alaoui",
        phone: "0668901245",
        city: "Casablanca",
        latitude: 33.5900,
        longitude: -7.6100,
        speciality: "Serrurerie",
        description: "Serrurier spécialisé en sécurité",
        hourly_rate: 110.00,
        is_available: true,
        average_rating: 4.5,
      },
      // Réparation électroménager
      {
        id: 9,
        full_name: "Youssef Bennani",
        phone: "0669012356",
        city: "Marrakech",
        latitude: 31.6300,
        longitude: -8.0100,
        speciality: "Réparation électroménager",
        description: "Réparation tous types d'électroménager",
        hourly_rate: 115.00,
        is_available: true,
        average_rating: 4.3,
      },
      // Plâtrerie / Staff
      {
        id: 10,
        full_name: "Omar Fassi",
        phone: "0670123467",
        city: "Casablanca",
        latitude: 33.5750,
        longitude: -7.5850,
        speciality: "Plâtrerie / Staff",
        description: "Plâtrier expérimenté en décoration",
        hourly_rate: 105.00,
        is_available: true,
        average_rating: 4.6,
      },
      // Jardinage
      {
        id: 11,
        full_name: "Laila Moussaoui",
        phone: "0671234578",
        city: "Fez",
        latitude: 34.0400,
        longitude: -5.0050,
        speciality: "Jardinage",
        description: "Paysagiste et jardinière experte",
        hourly_rate: 90.00,
        is_available: true,
        average_rating: 4.7,
      },
      // Domotique
      {
        id: 12,
        full_name: "Technician Smart",
        phone: "0672345689",
        city: "Rabat",
        latitude: 34.0250,
        longitude: -6.8350,
        speciality: "Domotique",
        description: "Spécialiste en systèmes domotiques modernes",
        hourly_rate: 160.00,
        is_available: true,
        average_rating: 4.9,
      },
      // Étanchéité
      {
        id: 13,
        full_name: "Ibrahim Khaled",
        phone: "0673456790",
        city: "Casablanca",
        latitude: 33.5800,
        longitude: -7.5950,
        speciality: "Étanchéité",
        description: "Expert en étanchéité toiture et terrasse",
        hourly_rate: 145.00,
        is_available: true,
        average_rating: 4.8,
      },
      // Isolation thermique & phonique
      {
        id: 14,
        full_name: "Taha Bennani",
        phone: "0674567801",
        city: "Marrakech",
        latitude: 31.6250,
        longitude: -8.0150,
        speciality: "Isolation thermique & phonique",
        description: "Spécialiste en isolation écologique",
        hourly_rate: 140.00,
        is_available: true,
        average_rating: 4.7,
      },
      // Nettoyage
      {
        id: 15,
        full_name: "Zainab Idrissi",
        phone: "0675678912",
        city: "Tangier",
        latitude: 35.7700,
        longitude: -5.8200,
        speciality: "Nettoyage",
        description: "Service de nettoyage professionnel",
        hourly_rate: 80.00,
        is_available: true,
        average_rating: 4.4,
      },
      // Panneaux solaires
      {
        id: 16,
        full_name: "Majid Tahri",
        phone: "0676789023",
        city: "Agadir",
        latitude: 30.4300,
        longitude: -9.6000,
        speciality: "Panneaux solaires",
        description: "Installation et maintenance énergie solaire",
        hourly_rate: 155.00,
        is_available: true,
        average_rating: 4.9,
      },
      // Installation TV / Satellite
      {
        id: 17,
        full_name: "Hassan Taouil",
        phone: "0677890134",
        city: "Fez",
        latitude: 34.0350,
        longitude: -5.0100,
        speciality: "Installation TV / Satellite",
        description: "Installateur TV et systèmes satellite certifié",
        hourly_rate: 95.00,
        is_available: true,
        average_rating: 4.5,
      },
      // Rénovation générale
      {
        id: 18,
        full_name: "Construction Pro",
        phone: "0678901245",
        city: "Casablanca",
        latitude: 33.5700,
        longitude: -7.6000,
        speciality: "Rénovation générale",
        description: "Entreprise spécialisée en rénovation complète",
        hourly_rate: 170.00,
        is_available: true,
        average_rating: 4.8,
      },
      // Démolition
      {
        id: 19,
        full_name: "Mourad Kharchi",
        phone: "0679012356",
        city: "Marrakech",
        latitude: 31.6350,
        longitude: -8.0050,
        speciality: "Démolition",
        description: "Service de démolition sécurisée et professionnelle",
        hourly_rate: 200.00,
        is_available: true,
        average_rating: 4.6,
      },
    ];

    return res.status(200).json(mockArtisans);
  } catch (err) {
    console.error('[ArtisanController] Erreur getAllArtisans:', err);
    return res.status(500).json({ error: 'Erreur serveur interne.' });
  }
};

module.exports = { getAllArtisans };
