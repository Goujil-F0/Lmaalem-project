const express = require('express');
const dotenv = require('dotenv');
const path = require('path');
const cors = require('cors');

dotenv.config();

const app = express(); // ← une seule fois

// Middleware
app.use(cors());
app.use(express.json());

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

// Route de test
app.get('/', (req, res) => {
  res.json({ message: '🚀 Bienvenue sur l\'API Maalem !' });
});

const PORT = process.env.PORT || 8081;
app.listen(PORT, () => {
  console.log(`🚀 Serveur Maalem lancé sur le port ${PORT}`);
});