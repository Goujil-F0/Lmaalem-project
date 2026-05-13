const express = require('express');
const dotenv = require('dotenv');
const cors = require('cors');
const http = require('http');
const { Server } = require('socket.io');
const MessageModel = require('./models/messageModel'); // Pour sauvegarder les messages dans la BDD

dotenv.config();

const app = express();

// On englobe l'application Express dans un serveur HTTP classique
const server = http.createServer(app);

// On initialise Socket.io avec les autorisations CORS (très important pour Flutter Web)
const io = new Server(server, {
    cors: {
        origin: "*", // Autorise tout le monde à se connecter au socket
        methods: ["GET", "POST"]
    }
});

// Middleware
app.use(cors());
app.use(express.json());

// Routes
const authRoutes = require('./routes/authRoutes');
const reviewRoutes = require('./routes/reviewRoutes'); 
const complaintRoutes = require('./routes/complaintRoutes');
const dashboardRoutes = require('./routes/dashboardRoutes'); 
const bookingRoutes = require('./routes/bookingRoutes');
const messageRoutes = require('./routes/messageRoutes');


app.use('/auth', authRoutes);
app.use('/api/reviews', reviewRoutes);
app.use('/api/complaints', complaintRoutes);
app.use('/api/dashboard', dashboardRoutes);
app.use('/api/bookings', bookingRoutes);
app.use('/api/messages', messageRoutes);

// Route de test
app.get('/', (req, res) => {
  res.json({ message: '🚀 Bienvenue sur l\'API Maalem !' });
});

// --- LOGIQUE TEMPS RÉEL (SOCKET.IO) ---
io.on('connection', (socket) => {
    console.log(`🔌 Nouvel appareil connecté au Chat : ${socket.id}`);

    // 1. L'utilisateur rejoint le "salon" privé de sa réservation
    socket.on('join_chat', (bookingId) => {
        socket.join(bookingId.toString());
        console.log(`👤 L'utilisateur a rejoint le chat de la réservation #${bookingId}`);
    });

    // 2. L'utilisateur envoie un message
    socket.on('send_message', async (data) => {
        // data contient : { bookingId, senderId, content }
        console.log("💬 Nouveau message reçu :", data.content);

        try {
            // A. Sauvegarder le message dans PostgreSQL
            const savedMessage = await MessageModel.saveMessage(
                data.bookingId, 
                data.senderId, 
                data.content
            );

            // B. Renvoyer le message à tous ceux qui sont dans ce salon (pour l'afficher à l'écran)
            io.to(data.bookingId.toString()).emit('receive_message', savedMessage);
            
        } catch (error) {
            console.error("Erreur de sauvegarde du message:", error);
        }
    });

    // 3. Déconnexion
    socket.on('disconnect', () => {
        console.log(`🔌 Appareil déconnecté : ${socket.id}`);
    });
});

// --- DÉMARRAGE DU SERVEUR ---
// ATTENTION : On utilise "server.listen" et non plus "app.listen" !
const PORT = process.env.PORT || 8081;
server.listen(PORT, () => {
    console.log(`🚀 Serveur Maalem & Socket.io lancés sur le port ${PORT}`);
});