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
    
    if (role === 'client') {
        query = `
            SELECT b.*, artisan.full_name AS artisan_name, client.full_name AS client_name,
                   (r.id IS NOT NULL) AS has_review,
                   artisan.full_name AS other_party_name,
                   (SELECT COUNT(*) FROM messages m WHERE m.booking_id = b.id AND m.sender_id != $1 AND m.is_read = FALSE) AS unread_count
            FROM bookings b
            JOIN users artisan ON artisan.id = b.artisan_id
            JOIN users client ON client.id = b.client_id
            LEFT JOIN reviews r ON r.booking_id = b.id
            WHERE b.client_id = $1
            ORDER BY b.created_at DESC;
        `;
    } else if (role === 'artisan') {
        query = `
            SELECT b.*, artisan.full_name AS artisan_name, client.full_name AS client_name,
                   (r.id IS NOT NULL) AS has_review,
                   client.full_name AS other_party_name,
                   (SELECT COUNT(*) FROM messages m WHERE m.booking_id = b.id AND m.sender_id != $1 AND m.is_read = FALSE) AS unread_count
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

const calculateCommission = (booking) => {
    const agreedPrice = parseFloat(booking.agreed_price || 0);
    const commissionPct = parseFloat(booking.commission_pct || 10);
    return Math.round((agreedPrice * commissionPct / 100) * 100) / 100;
};

const hasCommissionTransaction = async (client, walletId, bookingId) => {
    const { rows } = await client.query(
        `SELECT id
         FROM transactions
         WHERE wallet_id = $1
           AND type = 'commission'
           AND description LIKE $2
         LIMIT 1`,
        [walletId, `%reservation #${bookingId}%`]
    );
    return rows.length > 0;
};

const debitBookingCommission = async (client, wallet, booking, reason) => {
    const alreadyDebited = await hasCommissionTransaction(client, wallet.id, booking.id);
    if (alreadyDebited) return 0;

    const commission = calculateCommission(booking);
    const balance = parseFloat(wallet.balance || 0);

    if (commission <= 0) return 0;

    if (balance < commission) {
        const error = new Error(`Solde wallet insuffisant. Commission requise: ${commission.toFixed(2)} MAD. Solde actuel: ${balance.toFixed(2)} MAD.`);
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
            `${reason} reservation #${booking.id}`
        ]
    );

    return commission;
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
            await debitBookingCommission(client, wallet, booking, 'Commission acceptation');
        }

        if (newStatus === 'paid_cash') {
            // On ne peut passer en paid_cash que si on est en 'accepted' ou 'completed'
            if (!['accepted', 'completed'].includes(booking.status)) {
                const error = new Error(`Vous ne pouvez marquer comme payé que les réservations acceptées ou terminées. Statut actuel: ${booking.status}`);
                error.statusCode = 400;
                throw error;
            }

            // Si déjà payé, retourner le booking tel quel
            if (booking.status === 'paid_cash') {
                await client.query('COMMIT');
                return booking;
            }

            const wallet = await ensureWallet(client, booking.artisan_id);
            await debitBookingCommission(client, wallet, booking, 'Commission paiement cash');
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
    getUserById,
    getBookingsByUser,
    updateBookingStatus
};
