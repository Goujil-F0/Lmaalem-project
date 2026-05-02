const express = require('express');
const dotenv = require('dotenv');
const cors = require('cors');

dotenv.config();

const app = express();

// Middleware
app.use(cors());
app.use(express.json());

// Routes
const authRoutes = require('./routes/authRoutes');
app.use('/auth', authRoutes);

// Route de test
app.get('/', (req, res) => {
  res.json({ message: '🚀 Bienvenue sur l\'API Maalem !' });
});

const PORT = process.env.PORT || 8081;
app.listen(PORT, () => {
  console.log(`🚀 Serveur Maalem lancé sur le port ${PORT}`);
});