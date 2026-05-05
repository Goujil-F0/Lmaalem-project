const express = require('express');
const dotenv = require('dotenv');
const cors = require('cors');

dotenv.config();

const app = express();

// Middlewares globaux
app.use(cors());
app.use(express.json());

// Rate limiting global sur /api
const { apiLimiter } = require('./middleware/rateLimiter');
app.use('/api', apiLimiter);

// Routes
const authRoutes = require('./routes/authRoutes');
app.use('/auth', authRoutes);

const artisanRoutes = require('./routes/artisanRoutes');
app.use('/api', artisanRoutes);

// Sanity check
app.get('/', (req, res) => {
  res.json({ success: true, message: '🚀 API Lmaalem opérationnelle.' });
});

// 404 — doit être avant errorHandler
const notFound = require('./middleware/notFound');
app.use(notFound);

// Gestionnaire d'erreurs global — TOUJOURS en dernier
const errorHandler = require('./middleware/errorHandler');
app.use(errorHandler);

const PORT = process.env.PORT || 8081;
app.listen(PORT, () => {
  console.log(`🚀 Serveur Lmaalem sur le port ${PORT}`);
});