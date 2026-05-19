const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { createUser, findUserByEmail } = require('../models/userModel');

// ─── REGISTER ───────────────────────────────────────────
const register = async (req, res) => {
  try {
    const { full_name, email, password, role, phone, city, neighborhood, latitude, longitude } = req.body;

    // 1. Vérifier les champs obligatoires
    if (!full_name || !email || !password || !role) {
      return res.status(400).json({ error: 'Champs obligatoires : full_name, email, password, role' });
    }

    // 2. Vérifier le role
    if (!['client', 'artisan'].includes(role)) {
      return res.status(400).json({ error: 'Role invalide. Choisir : client ou artisan' });
    }

    // 3. Vérifier si email déjà utilisé
    const existingUser = await findUserByEmail(email);
    if (existingUser) {
      return res.status(409).json({ error: 'Cet email est déjà utilisé' });
    }

    // 4. Hasher le mot de passe
    const password_hash = await bcrypt.hash(password, 10);

    // 5. Créer l'utilisateur
    const user = await createUser(
      full_name, email, password_hash, role,
      phone, city, neighborhood, latitude, longitude
    );

    // 6. Générer le token JWT
    const token = jwt.sign(
      { id: user.id, email: user.email, role: user.role },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );

    // 7. Répondre
    res.status(201).json({ token, user });

  } catch (error) {
    console.error('Register error:', error.message);
    res.status(500).json({ error: 'Erreur serveur' });
  }
};

// ─── LOGIN ──────────────────────────────────────────────
const login = async (req, res) => {
  try {
    const { email, password } = req.body;

    // 1. Vérifier les champs
    if (!email || !password) {
      return res.status(400).json({ error: 'Email et password obligatoires' });
    }

    // 2. Chercher l'utilisateur
    const user = await findUserByEmail(email);
    if (!user) {
      return res.status(401).json({ error: 'Email ou mot de passe incorrect' });
    }

    // 3. Vérifier le mot de passe
    const isValid = await bcrypt.compare(password, user.password_hash);
    if (!isValid) {
      return res.status(401).json({ error: 'Email ou mot de passe incorrect' });
    }

    // 4. Générer le token JWT
    const token = jwt.sign(
      { id: user.id, email: user.email, role: user.role },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );

    // 5. Répondre sans le password_hash
    const { password_hash, ...userSafe } = user;
    res.status(200).json({ token, user: userSafe });

  } catch (error) {
    console.error('Login error:', error.message);
    res.status(500).json({ error: 'Erreur serveur' });
  }
};


// ─── UploadCIN ──────────────────────────────────────────────
const uploadCinHandler = async (req, res) => {
  try {
    // 1. Vérifier que les deux fichiers sont présents
    if (!req.files?.cin_recto || !req.files?.cin_verso) {
      return res.status(400).json({ 
        error: 'Les deux côtés de la CIN sont obligatoires' 
      });
    }

    const rectoUrl = `/uploads/cin/${req.files.cin_recto[0].filename}`;
    const versoUrl = `/uploads/cin/${req.files.cin_verso[0].filename}`;

    // 2. Mettre à jour artisan_profiles
    const db = require('../models/db');
    await db.query(
      `UPDATE artisan_profiles 
       SET cin_url = $1, cin_verified = false
       WHERE user_id = $2`,
      [`${rectoUrl}|${versoUrl}`, req.user.id]
    );

    res.status(200).json({
      message: 'CIN uploadée avec succès',
      cin_recto: rectoUrl,
      cin_verso: versoUrl,
    });

  } catch (error) {
    console.error('Upload CIN error:', error.message);
    res.status(500).json({ error: 'Erreur serveur' });
  }
};

module.exports = { register, login, uploadCinHandler };