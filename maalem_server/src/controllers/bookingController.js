// backend/controllers/bookingController.js
const BookingModel = require('../models/bookingModel');

const createNewBooking = async (req, res) => {
    try {
        // Normalement, le client_id viendra du JWT (req.user.id), mais pour l'instant on le prend du body
        const { client_id, artisan_id, description, agreed_price, booking_date } = req.body;

        // Validation basique
        if (!client_id || !artisan_id || !booking_date) {
            return res.status(400).json({ success: false, message: "Veuillez fournir les informations obligatoires." });
        }

        const newBooking = await BookingModel.createBooking(
            client_id, artisan_id, description, agreed_price, booking_date
        );

        const io = req.app.get('socketio');

        res.status(201).json({
            success: true,
            message: "Réservation créée avec succès.",
            data: newBooking
        });
    } catch (error) {
        console.error("Erreur lors de la création de la réservation:", error);
        res.status(500).json({ success: false, message: "Erreur interne du serveur." });
    }
};

// Fonction temporaire pour injecter des données de test
const seedTestUsers = async (req, res) => {
    try {
        // En regardant ton arborescence, la db est dans src/models/db.js
        const pool = require('../models/db'); 
        
        await pool.query(`
            INSERT INTO users (id, full_name, email, password_hash, role) 
            VALUES 
            (1, 'Client Test', 'client1@test.com', 'mdp123', 'client'), 
            (2, 'Artisan Test', 'artisan2@test.com', 'mdp123', 'artisan')
            ON CONFLICT (id) DO NOTHING;
        `);
        
        res.status(200).json({ success: true, message: "Utilisateurs de test injectés avec succès !" });
    } catch (error) {
        console.error("Erreur de seed:", error);
        res.status(500).json({ success: false, error: error.message });
    }
};

const getBookingHistory = async (req, res) => {
    try {
        // On récupère l'ID et le rôle depuis l'URL (ex: /api/bookings/history/1/client)
        const { userId, role } = req.params;

        const bookings = await BookingModel.getBookingsByUser(userId, role);

        res.status(200).json({
            success: true,
            count: bookings.length,
            data: bookings
        });
    } catch (error) {
        console.error("Erreur lors de la récupération de l'historique:", error);
        res.status(500).json({ success: false, message: "Erreur interne du serveur." });
    }
};

const updateStatus = async (req, res) => {
    try {
        const { id } = req.params; // L'ID de la réservation dans l'URL
        const { status } = req.body; // Le nouveau statut envoyé dans le corps de la requête

        if (!status) {
            return res.status(400).json({ success: false, message: "Le nouveau statut est requis." });
        }

        const updatedBooking = await BookingModel.updateBookingStatus(id, status);

        if (!updatedBooking) {
            return res.status(404).json({ success: false, message: "Réservation introuvable." });
        }

        res.status(200).json({
            success: true,
            message: `Réservation ${id} passée au statut : ${status}`,
            data: updatedBooking
        });
    } catch (error) {
        console.error("Erreur lors de la mise à jour du statut:", error);
        res.status(500).json({ success: false, message: "Erreur interne du serveur." });
    }
};

// Mets à jour ton export à la fin du fichier
module.exports = {
    createNewBooking,
    seedTestUsers,
    getBookingHistory,
    updateStatus
};

