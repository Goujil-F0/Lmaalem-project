// models/messageModel.js
const pool = require('./db'); // Assure-toi que le chemin est correct (celui que tu utilises dans bookingController)

const getBookingById = async (bookingId) => {
    const { rows } = await pool.query(
        `SELECT id, client_id, artisan_id
         FROM bookings
         WHERE id = $1`,
        [bookingId]
    );
    return rows[0] || null;
};

// 1. Sauvegarder un nouveau message
const saveMessage = async (bookingId, senderId, content) => {
    const query = `
        INSERT INTO messages (booking_id, sender_id, content, timestamp)
        VALUES ($1, $2, $3, NOW())
        RETURNING *;
    `;
    const { rows } = await pool.query(query, [bookingId, senderId, content]);
    return rows[0];
};

// 2. Récupérer tout l'historique d'un chat
const getMessagesByBooking = async (bookingId) => {
    const query = `
        SELECT * FROM messages 
        WHERE booking_id = $1 
        ORDER BY timestamp ASC;
    `;
    const { rows } = await pool.query(query, [bookingId]);
    return rows;
};

module.exports = {
    getBookingById,
    saveMessage,
    getMessagesByBooking
};
