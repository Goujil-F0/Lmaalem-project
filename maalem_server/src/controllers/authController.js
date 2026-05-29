const bcrypt = require('bcryptjs');
const fs = require('fs');
const jwt = require('jsonwebtoken');
const path = require('path');
const db = require('../models/db');
const { createUser, findUserByEmail } = require('../models/userModel');

const register = async (req, res) => {
  try {
    const {
      full_name,
      email,
      password,
      role,
      phone,
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

    const { password_hash, ...userSafe } = user;
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

    const userDir = path.join(__dirname, '..', '..', 'uploads', 'cin', String(req.user.id));
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

module.exports = {
  register,
  login,
  uploadCinHandler,
  updateAvailability,
};
