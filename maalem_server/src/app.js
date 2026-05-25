const express = require('express');
const dotenv = require('dotenv');
const path = require('path');
const cors = require('cors');

dotenv.config();

const app = express(); // ← une seule fois

// Middleware
app.use(express.json());
app.use(cors());

// Rate limiting global sur /api
const { apiLimiter } = require('./middleware/rateLimiter');
app.use('/api', apiLimiter);

// Routes
const authRoutes = require('./routes/authRoutes');
const reviewRoutes = require('./routes/reviewRoutes');
const complaintRoutes = require('./routes/complaintRoutes');
const dashboardRoutes = require('./routes/dashboardRoutes');

app.use('/auth', authRoutes);
app.use('/api/reviews', reviewRoutes);
app.use('/api/complaints', complaintRoutes);
app.use('/api/dashboard', dashboardRoutes);
app.use('/uploads', express.static(path.join(__dirname, '..', 'uploads')));

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