const jwt = require('jsonwebtoken');

const verifyToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ error: 'Accès refusé. Token manquant.' });
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.user = decoded;
    next();
  } catch (error) {
    return res.status(403).json({ error: 'Token invalide ou expiré.' });
  }
};

const verifyArtisan = (req, res, next) => {
  if (!req.user || req.user.role !== 'artisan') {
    return res.status(403).json({ error: 'Accès réservé aux artisans.' });
  }
  next();
};

const verifyClient = (req, res, next) => {
  if (!req.user || req.user.role !== 'client') {
    return res.status(403).json({ error: 'Accès réservé aux clients.' });
  }
  next();
};

module.exports = { verifyToken, verifyArtisan, verifyClient };