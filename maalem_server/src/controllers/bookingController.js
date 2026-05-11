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

// N'oublie pas de l'exporter avec l'autre fonction !
module.exports = {
    createNewBooking,
    seedTestUsers
};

