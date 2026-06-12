const express = require('express');
const dotenv = require('dotenv');
const path = require('path');
const cors = require('cors');
const http = require('http');
const { Server } = require('socket.io');
const { createMessage } = require('./controllers/messageController');

dotenv.config({ path: path.resolve(__dirname, '../../.env') });

const app = express(); // ← une seule fois
const publicUploadsPath = path.join(__dirname, '..', '..', 'uploads');
const legacyUploadsPath = path.join(__dirname, '..', 'uploads');

// On englobe l'application Express dans un serveur HTTP classique
const server = http.createServer(app);

// On initialise Socket.io avec les autorisations CORS (très important pour Flutter Web)
const io = new Server(server, {
    cors: {
        origin: "*",
        methods: ["GET", "POST"]
    }
});
app.set('socketio', io);

// Middleware
app.use(express.json());
app.use(cors());

// Rate limiting global sur /api
const { apiLimiter, authLimiter } = require('./middleware/rateLimiter');
app.use('/api', apiLimiter);

// Routes
const authRoutes = require('./routes/authRoutes');
const reviewRoutes = require('./routes/reviewRoutes');
const complaintRoutes = require('./routes/complaintRoutes');
const dashboardRoutes = require('./routes/dashboardRoutes');
const bookingRoutes = require('./routes/bookingRoutes');
const messageRoutes = require('./routes/messageRoutes');
const artisanRoutes = require('./routes/artisanRoutes');

app.use('/auth', authRoutes);
app.use('/api/reviews', reviewRoutes);
app.use('/api/complaints', complaintRoutes);
app.use('/api/dashboard', dashboardRoutes);
app.use('/api/bookings', bookingRoutes);
app.use('/api/messages', messageRoutes);
app.use('/uploads', express.static(publicUploadsPath));
app.use('/uploads', express.static(legacyUploadsPath));
app.use('/api', artisanRoutes);

// Sanity check
app.get('/', (req, res) => {
  res.json({ success: true, message: '🚀 API Lmaalem opérationnelle.' });
});

// --- LOGIQUE TEMPS RÉEL (SOCKET.IO) ---
io.on('connection', (socket) => {
    console.log(' 🔌 Nouvel appareil connecté au Chat : ');

    // 1. L'utilisateur rejoint le "salon" privé de sa réservation
    socket.on('join_chat', (bookingId) => {
        socket.join(bookingId.toString());
        console.log(`👤 L'utilisateur a rejoint le chat de la réservation #`+ bookingId);
    });

    // 2. L'utilisateur envoie un message (avec ACK)
    socket.on('send_message', async (data, ack) => {
        console.log("💬 Nouveau message reçu :", data.content);

        try {
            const savedMessage = await createMessage(data);
            socket.to(savedMessage.booking_id.toString()).emit('receive_message', savedMessage);
            if (typeof ack === 'function') ack({ success: true, message: savedMessage });
        } catch (error) {
            console.error("Erreur de sauvegarde du message:", error);
            if (typeof ack === 'function') {
                ack({
                    success: false,
                    error: error.statusCode ? error.message : "Erreur de sauvegarde"
                });
            }
        }
    });

    // 3. Déconnexion
    socket.on('disconnect', () => {
        console.log(' 🔌 Appareil déconnecté : ');
    });
});

// 404 — doit être avant errorHandler
const notFound = require('./middleware/notFound');
app.use(notFound);

// Gestionnaire d'erreurs global — TOUJOURS en dernier
const errorHandler = require('./middleware/errorHandler');
app.use(errorHandler);

const PORT = process.env.PORT || 8081;
server.listen(PORT, () => {
    console.log('🚀 Serveur Maalem & Socket.io lancés sur le port ' + PORT);
});
