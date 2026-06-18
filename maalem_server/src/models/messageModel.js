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

const countUnreadMessages = async (bookingId, userId) => {
    const { rows } = await pool.query(
        `SELECT COUNT(*) FROM messages
         WHERE booking_id = $1 AND sender_id != $2 AND is_read = FALSE`,
        [bookingId, userId]
    );
    return parseInt(rows[0].count, 10);
};

const markAsRead = async (bookingId, userId) => {
    await pool.query(
        `UPDATE messages
         SET is_read = TRUE
         WHERE booking_id = $1 AND sender_id != $2`,
        [bookingId, userId]
    );
};

module.exports = {
    getBookingById,
    saveMessage,
    getMessagesByBooking,
    countUnreadMessages,
    markAsRead
};
