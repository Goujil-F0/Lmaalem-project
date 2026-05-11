// backend/models/bookingModel.js
const pool = require('./db'); // Vérifie que ce chemin correspond au fichier de configuration de Fatima

const createBooking = async (clientId, artisanId, description, agreedPrice, bookingDate) => {
    const query = `
        INSERT INTO bookings (client_id, artisan_id, description, agreed_price, booking_date)
        VALUES ($1, $2, $3, $4, $5)
        RETURNING *;
    `;
    const values =[clientId, artisanId, description, agreedPrice, bookingDate];
    
    const { rows } = await pool.query(query, values);
    return rows[0]; // On retourne la réservation nouvellement créée
};

module.exports = {
    createBooking
};