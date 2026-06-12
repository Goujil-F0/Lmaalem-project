// models/messageModel.js
const pool = require('./db'); // Assure-toi que le chemin est correct (celui que tu utilises dans bookingController)

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

// Compter les messages non lus par l'utilisateur actuel
const countUnreadMessages = async (bookingId, userId) => {
    const query = `
        SELECT COUNT(*) FROM messages 
        WHERE booking_id = $1 AND sender_id != $2 AND is_read = FALSE;
    `;
    const { rows } = await pool.query(query, [bookingId, userId]);
    return parseInt(rows[0].count, 10);
};

const markAsRead = async (bookingId, userId) => {
    // Met is_read = TRUE pour tous les messages de ce chat qui n'ont pas été envoyés par moi
    await pool.query(`UPDATE messages SET is_read = TRUE WHERE booking_id = $1 AND sender_id != $2`, [bookingId, userId]);
};
module.exports = { saveMessage, getMessagesByBooking, countUnreadMessages, markAsRead };