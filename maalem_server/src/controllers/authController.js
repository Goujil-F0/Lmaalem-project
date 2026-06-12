const bcrypt = require('bcryptjs');
const fs = require('fs');
const jwt = require('jsonwebtoken');
const path = require('path');
const db = require('../models/db');
const { createUser, findUserByEmail } = require('../models/userModel');

const getUserWithProfile = async (userId) => {
  const result = await db.query(
    `SELECT u.id,
            u.full_name,
            u.email,
            u.role,
            u.phone,
            u.city,
            u.neighborhood,
            u.latitude,
            u.longitude,
            COALESCE(u.profile_photo_url, ap.profile_photo_url) AS photo_url,
            json_build_object(
              'user_id', ap.user_id,
              'specialty_id', ap.specialty_id,
              'specialty', s.name,
              'description', ap.description,
              'hourly_rate', ap.hourly_rate,
              'is_available', COALESCE(ap.is_available, true),
              'cin_url', ap.cin_url,
              'cin_verified', COALESCE(ap.cin_verified, false),
              'average_rating', COALESCE(ap.average_rating, 0),
              'profile_photo_url', ap.profile_photo_url,
              'portfolio_images', COALESCE(ap.portfolio_images, ARRAY[]::TEXT[])
            ) AS profile
     FROM users u
     LEFT JOIN artisan_profiles ap ON ap.user_id = u.id
     LEFT JOIN specialties s ON s.id = ap.specialty_id
     WHERE u.id = $1`,
    [userId]
  );

  const user = result.rows[0];
  if (!user) return null;
  if (user.role !== 'artisan' || user.profile?.user_id === null) {
    user.profile = null;
  }
  return user;
};

const register = async (req, res) => {
  try {
    const {
      full_name,
      email,
      password,
      role,
      phone,
      specialty,
      city,
      neighborhood,
      latitude,
      longitude,
    } = req.body;

    if (!full_name || !email || !password || !role) {
      return res.status(400).json({
        error: 'Champs obligatoires : full_name, email, password, role',
      });
    }

    if (!['client', 'artisan'].includes(role)) {
      return res.status(400).json({ error: 'Role invalide. Choisir : client ou artisan' });
    }

    const existingUser = await findUserByEmail(email);
    if (existingUser) {
      return res.status(409).json({ error: 'Cet email est deja utilise' });
    }

    const password_hash = await bcrypt.hash(password, 10);
    const user = await createUser(
      full_name,
      email,
      password_hash,
      role,
      phone,
      city,
      neighborhood,
      latitude,
      longitude
    );

    if (role === 'artisan' && specialty && specialty.trim()) {
      const specialtyResult = await db.query(
        `INSERT INTO specialties (group_id, name)
         VALUES ((SELECT id FROM category_groups ORDER BY id LIMIT 1), $1)
         ON CONFLICT (name) DO UPDATE SET name = EXCLUDED.name
         RETURNING id`,
        [specialty.trim()]
      );

      await db.query(
        `UPDATE artisan_profiles
         SET specialty_id = $1
         WHERE user_id = $2`,
        [specialtyResult.rows[0].id, user.id]
      );
    }

    const token = jwt.sign(
      { id: user.id, email: user.email, role: user.role },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );

    res.status(201).json({ token, user });
  } catch (error) {
    console.error('Register error:', error.message);
    res.status(500).json({ error: 'Erreur serveur' });
  }
};

const login = async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ error: 'Email et password obligatoires' });
    }

    const user = await findUserByEmail(email);
    if (!user) {
      return res.status(401).json({ error: 'Email ou mot de passe incorrect' });
    }

    const isValid = await bcrypt.compare(password, user.password_hash);
    if (!isValid) {
      return res.status(401).json({ error: 'Email ou mot de passe incorrect' });
    }

    const token = jwt.sign(
      { id: user.id, email: user.email, role: user.role },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );

    const userSafe = await getUserWithProfile(user.id);
    res.status(200).json({ token, user: userSafe });
  } catch (error) {
    console.error('Login error:', error.message);
    res.status(500).json({ error: 'Erreur serveur' });
  }
};

const uploadCinHandler = async (req, res) => {
  try {
    if (!req.files?.cin_recto || !req.files?.cin_verso) {
      return res.status(400).json({
        error: 'Les deux cotes de la CIN sont obligatoires',
      });
    }

    const userDir = path.join(__dirname, '..', '..', '..', 'uploads', 'cin', String(req.user.id));
    fs.mkdirSync(userDir, { recursive: true });

    const rectoUrl = `/uploads/cin/${req.user.id}/${req.files.cin_recto[0].filename}`;
    const versoUrl = `/uploads/cin/${req.user.id}/${req.files.cin_verso[0].filename}`;

    await db.query(
      `UPDATE artisan_profiles
       SET cin_url = $1, cin_verified = false
       WHERE user_id = $2`,
      [`${rectoUrl}|${versoUrl}`, req.user.id]
    );

    res.status(200).json({
      message: 'CIN uploadee avec succes',
      cin_recto: rectoUrl,
      cin_verso: versoUrl,
    });
  } catch (error) {
    console.error('Upload CIN error:', error.message);
    res.status(500).json({ error: 'Erreur serveur' });
  }
};

const updateAvailability = async (req, res) => {
  try {
    const { is_available } = req.body;

    if (typeof is_available !== 'boolean') {
      return res.status(400).json({ error: 'is_available doit etre un booleen' });
    }

    await db.query(
      'UPDATE artisan_profiles SET is_available = $1 WHERE user_id = $2',
      [is_available, req.user.id]
    );

    res.json({ message: 'Statut mis a jour', is_available });
  } catch (error) {
    console.error('Availability error:', error.message);
    res.status(500).json({ error: 'Erreur serveur' });
  }
};

const updateClientProfile = async (req, res) => {
  try {
    const {
      full_name,
      email,
      phone,
      city,
      neighborhood,
      latitude,
      longitude,
    } = req.body;

    const result = await db.query(
      `UPDATE users
       SET full_name = COALESCE($1, full_name),
           email = COALESCE($2, email),
           phone = COALESCE($3, phone),
           city = COALESCE($4, city),
           neighborhood = COALESCE($5, neighborhood),
           latitude = COALESCE($6, latitude),
           longitude = COALESCE($7, longitude)
       WHERE id = $8
       RETURNING id`,
      [full_name, email, phone, city, neighborhood, latitude, longitude, req.user.id]
    );

    const user = result.rows[0] ? await getUserWithProfile(result.rows[0].id) : null;
    res.json({ message: 'Profil mis a jour', user });
  } catch (error) {
    console.error('Update profile error:', error.message);
    res.status(500).json({ error: 'Erreur serveur' });
  }
};

const updateArtisanProfile = async (req, res) => {
  try {
    const { specialty, hourly_rate, description } = req.body;
    let specialtyId = null;

    if (specialty && specialty.trim()) {
      const specialtyResult = await db.query(
        `INSERT INTO specialties (group_id, name)
         VALUES ((SELECT id FROM category_groups ORDER BY id LIMIT 1), $1)
         ON CONFLICT (name) DO UPDATE SET name = EXCLUDED.name
         RETURNING id`,
        [specialty.trim()]
      );
      specialtyId = specialtyResult.rows[0].id;
    }

    await db.query(
      `INSERT INTO artisan_profiles (user_id, specialty_id, hourly_rate, description, is_available)
       VALUES ($1, $2, $3, $4, true)
       ON CONFLICT (user_id) DO UPDATE
       SET specialty_id = COALESCE(EXCLUDED.specialty_id, artisan_profiles.specialty_id),
           hourly_rate = COALESCE(EXCLUDED.hourly_rate, artisan_profiles.hourly_rate),
           description = COALESCE(EXCLUDED.description, artisan_profiles.description)`,
      [req.user.id, specialtyId, hourly_rate, description]
    );

    const user = await getUserWithProfile(req.user.id);
    res.json({ message: 'Profil artisan mis a jour', user });
  } catch (error) {
    console.error('Update artisan profile error:', error.message);
    res.status(500).json({ error: 'Erreur serveur' });
  }
};

const uploadProfilePhotoHandler = async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'Photo de profil obligatoire' });
    }

    const photoUrl = `/uploads/profile/${req.user.id}/${req.file.filename}`;

    await db.query(
      `UPDATE users
       SET profile_photo_url = $1
       WHERE id = $2`,
      [photoUrl, req.user.id]
    );

    if (req.user.role === 'artisan') {
      await db.query(
        `INSERT INTO artisan_profiles (user_id, profile_photo_url, is_available)
         VALUES ($1, $2, true)
         ON CONFLICT (user_id) DO UPDATE
         SET profile_photo_url = EXCLUDED.profile_photo_url`,
        [req.user.id, photoUrl]
      );
    }

    const user = await getUserWithProfile(req.user.id);
    if (user) user.photo_url = photoUrl;
    res.status(200).json({
      message: 'Photo de profil mise a jour',
      photo_url: photoUrl,
      user,
    });
  } catch (error) {
    console.error('Upload profile photo error:', error.message);
    res.status(500).json({ error: 'Erreur serveur' });
  }
};

const uploadPortfolioHandler = async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'Image portfolio obligatoire' });
    }

    const imageUrl = `/uploads/portfolio/${req.user.id}/${req.file.filename}`;

    await db.query(
      `INSERT INTO artisan_profiles (user_id, portfolio_images, is_available)
       VALUES ($1, ARRAY[$2]::TEXT[], true)
       ON CONFLICT (user_id) DO UPDATE
       SET portfolio_images = array_append(
         COALESCE(artisan_profiles.portfolio_images, ARRAY[]::TEXT[]),
         $2
       )`,
      [req.user.id, imageUrl]
    );

    const user = await getUserWithProfile(req.user.id);
    res.status(201).json({
      message: 'Image ajoutee au portfolio',
      image_url: imageUrl,
      user,
    });
  } catch (error) {
    console.error('Upload portfolio error:', error.message);
    res.status(500).json({ error: 'Erreur serveur' });
  }
};

const replacePortfolioImageHandler = async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'Image portfolio obligatoire' });
    }

    const imageIndex = Number.parseInt(req.params.index, 10);
    if (!Number.isInteger(imageIndex) || imageIndex < 0) {
      return res.status(400).json({ error: 'Index portfolio invalide' });
    }

    const imageUrl = `/uploads/portfolio/${req.user.id}/${req.file.filename}`;
    const postgresIndex = imageIndex + 1;

    const result = await db.query(
      `UPDATE artisan_profiles
       SET portfolio_images[$2] = $3
       WHERE user_id = $1
         AND portfolio_images IS NOT NULL
         AND array_length(portfolio_images, 1) >= $2
       RETURNING portfolio_images`,
      [req.user.id, postgresIndex, imageUrl]
    );

    if (result.rowCount === 0) {
      return res.status(404).json({ error: 'Image portfolio introuvable' });
    }

    const user = await getUserWithProfile(req.user.id);
    res.status(200).json({
      message: 'Image portfolio mise a jour',
      image_url: imageUrl,
      user,
    });
  } catch (error) {
    console.error('Replace portfolio image error:', error.message);
    res.status(500).json({ error: 'Erreur serveur' });
  }
};

module.exports = {
  register,
  login,
  uploadCinHandler,
  updateAvailability,
  updateClientProfile,
  updateArtisanProfile,
  uploadProfilePhotoHandler,
  uploadPortfolioHandler,
  replacePortfolioImageHandler,
  getUserWithProfile,
};
