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
    
    // Si c'est un client, on cherche ses réservations
    if (role === 'client') {
        query = `
            SELECT b.*, artisan.full_name AS artisan_name, client.full_name AS client_name,
                   (r.id IS NOT NULL) AS has_review
            FROM bookings b
            JOIN users artisan ON artisan.id = b.artisan_id
            JOIN users client ON client.id = b.client_id
            LEFT JOIN reviews r ON r.booking_id = b.id
            WHERE b.client_id = $1
            ORDER BY b.created_at DESC;
        `;
    } 
    // Si c'est un artisan, on cherche les siennes
    else if (role === 'artisan') {
        query = `
            SELECT b.*, artisan.full_name AS artisan_name, client.full_name AS client_name,
                   (r.id IS NOT NULL) AS has_review
            FROM bookings b
            JOIN users artisan ON artisan.id = b.artisan_id
            JOIN users client ON client.id = b.client_id
            LEFT JOIN reviews r ON r.booking_id = b.id
            WHERE b.artisan_id = $1
            ORDER BY b.created_at DESC;
        `;
    } else {
        throw new Error("Rôle invalide");
    }

    const { rows } = await pool.query(query, [userId]);
    return rows;
};

const ensureWallet = async (client, artisanId) => {
    const { rows } = await client.query(
        `INSERT INTO wallets (user_id, balance)
         VALUES ($1, 0)
         ON CONFLICT (user_id) DO UPDATE SET user_id = EXCLUDED.user_id
         RETURNING *`,
        [artisanId]
    );
    return rows[0];
};

const updateBookingStatus = async (bookingId, newStatus) => {
    const client = await pool.connect();

    try {
        await client.query('BEGIN');

        const bookingResult = await client.query(
            `SELECT * FROM bookings WHERE id = $1 FOR UPDATE`,
            [bookingId]
        );
        const booking = bookingResult.rows[0];

        if (!booking) {
            await client.query('ROLLBACK');
            return null;
        }

        if (newStatus === 'accepted') {
            const wallet = await ensureWallet(client, booking.artisan_id);
            const balance = parseFloat(wallet.balance || 0);

            if (balance <= 0) {
                const error = new Error('Solde wallet insuffisant. Rechargez votre compte pour accepter de nouvelles missions.');
                error.statusCode = 409;
                throw error;
            }
        }

        if (newStatus === 'paid_cash') {
            if (booking.status === 'paid_cash' || booking.status === 'completed') {
                await client.query('COMMIT');
                return booking;
            }

            const wallet = await ensureWallet(client, booking.artisan_id);
            const agreedPrice = parseFloat(booking.agreed_price || 0);
            const commissionPct = parseFloat(booking.commission_pct || 10);
            const commission = Math.round((agreedPrice * commissionPct / 100) * 100) / 100;
            const balance = parseFloat(wallet.balance || 0);

            if (balance < commission) {
                const error = new Error(`Solde wallet insuffisant pour declarer le paiement cash. Commission requise: ${commission.toFixed(2)} MAD.`);
                error.statusCode = 409;
                throw error;
            }

            await client.query(
                `UPDATE wallets
                 SET balance = balance - $1, updated_at = CURRENT_TIMESTAMP
                 WHERE id = $2`,
                [commission, wallet.id]
            );

            await client.query(
                `INSERT INTO transactions (wallet_id, amount, type, description)
                 VALUES ($1, $2, 'commission', $3)`,
                [
                    wallet.id,
                    -commission,
                    `Commission paiement cash reservation #${booking.id}`
                ]
            );
        }

        const { rows } = await client.query(
            `UPDATE bookings
             SET status = $1
             WHERE id = $2
             RETURNING *`,
            [newStatus, bookingId]
        );

        await client.query('COMMIT');
        return rows[0]; // Retourne la réservation modifiée
    } catch (error) {
        await client.query('ROLLBACK');
        throw error;
    } finally {
        client.release();
    }
};

// Mets à jour ton export à la fin du fichier
module.exports = {
    createBooking,
    getBookingsByUser,
    updateBookingStatus
};
