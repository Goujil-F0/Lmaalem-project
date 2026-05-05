// middleware/rateLimiter.js
const rateLimit = require('express-rate-limit');

// Pour login / register : 10 tentatives / 15 min
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 10,
  message: {
    success: false,
    error: 'Trop de tentatives. Réessayez dans 15 minutes.',
  },
  standardHeaders: true,
  legacyHeaders: false,
});

// Pour les routes API générales : 100 req / min
const apiLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 100,
  message: {
    success: false,
    error: 'Trop de requêtes. Ralentissez.',
  },
});

module.exports = { authLimiter, apiLimiter };