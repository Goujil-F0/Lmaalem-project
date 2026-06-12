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

const getBookingsByUser = async (userId, role) => {
    let query = '';
    
    if (role === 'client') {
        // On récupère les infos de l'artisan (table users 'a')
        query = `
            SELECT b.*, 
                   a.full_name AS other_party_name,
                   (SELECT COUNT(*) FROM messages m WHERE m.booking_id = b.id AND m.sender_id != $1 AND m.is_read = FALSE) AS unread_count
            FROM bookings b 
            JOIN users a ON b.artisan_id = a.id
            WHERE b.client_id = $1 
            ORDER BY b.created_at DESC;
        `;
    } else if (role === 'artisan') {
        // On récupère les infos du client (table users 'c')
        query = `
            SELECT b.*, 
                   c.full_name AS other_party_name,
                   (SELECT COUNT(*) FROM messages m WHERE m.booking_id = b.id AND m.sender_id != $1 AND m.is_read = FALSE) AS unread_count
            FROM bookings b 
            JOIN users c ON b.client_id = c.id
            WHERE b.artisan_id = $1 
            ORDER BY b.created_at DESC;
        `;
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
    getBookingsByUser,
    updateBookingStatus
};