const pool = require('./db');

let timestampColumn;

const getTimestampColumn = async () => {
    if (timestampColumn) return timestampColumn;

    const { rows } = await pool.query(
        `SELECT column_name
         FROM information_schema.columns
         WHERE table_name = 'messages'
           AND column_name IN ('timestamp', 'created_at')`
    );

    timestampColumn = rows.some((row) => row.column_name === 'timestamp')
        ? 'timestamp'
        : 'created_at';
    return timestampColumn;
};

const getBookingById = async (bookingId) => {
    const { rows } = await pool.query(
        `SELECT id, client_id, artisan_id
         FROM bookings
         WHERE id = $1`,
        [bookingId]
    );
    return rows[0] || null;
};

const saveMessage = async (bookingId, senderId, content) => {
    const messageTimestampColumn = await getTimestampColumn();
    const { rows } = await pool.query(
        `INSERT INTO messages (booking_id, sender_id, content, ${messageTimestampColumn})
         VALUES ($1, $2, $3, NOW())
         RETURNING *, ${messageTimestampColumn} AS timestamp`,
        [bookingId, senderId, content]
    );
    return rows[0];
};

const getMessagesByBooking = async (bookingId) => {
    const messageTimestampColumn = await getTimestampColumn();
    const { rows } = await pool.query(
        `SELECT *, ${messageTimestampColumn} AS timestamp
         FROM messages
         WHERE booking_id = $1
         ORDER BY ${messageTimestampColumn} ASC`,
        [bookingId]
    );
    return rows;
};

<<<<<<< HEAD
module.exports = {
    getBookingById,
    saveMessage,
    getMessagesByBooking
};
=======
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
>>>>>>> origin/feature/wissal-avis-dashboard-reclamations
