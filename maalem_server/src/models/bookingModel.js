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

const getUserById = async (userId) => {
    const { rows } = await pool.query(
        'SELECT id, role FROM users WHERE id = $1',
        [userId]
    );
    return rows[0] || null;
};

const getBookingsByUser = async (userId, role) => {
    let query = '';
    
    // Si c'est un client, on cherche ses réservations
    if (role === 'client') {
        query = `SELECT * FROM bookings WHERE client_id = $1 ORDER BY created_at DESC;`;
    } 
    // Si c'est un artisan, on cherche les siennes
    else if (role === 'artisan') {
        query = `SELECT * FROM bookings WHERE artisan_id = $1 ORDER BY created_at DESC;`;
    } else {
        throw new Error("Rôle invalide");
    }

    const { rows } = await pool.query(query, [userId]);
    return rows;
};

const updateBookingStatus = async (bookingId, newStatus) => {
    const query = `
        UPDATE bookings 
        SET status = $1 
        WHERE id = $2 
        RETURNING *;
    `;
    const { rows } = await pool.query(query, [newStatus, bookingId]);
    return rows[0]; // Retourne la réservation modifiée
};

// Mets à jour ton export à la fin du fichier
module.exports = {
    createBooking,
    getUserById,
    getBookingsByUser,
    updateBookingStatus
};
