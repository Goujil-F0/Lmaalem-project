// Fix booking constraint - add paid_cash status
const { Pool } = require('pg');
const path = require('path');
require('dotenv').config({ path: path.resolve(__dirname, '../../.env') });

const pool = new Pool({
    user: process.env.DB_USER,
    host: process.env.DB_HOST,
    database: process.env.DB_NAME,
    password: process.env.DB_PASSWORD,
    port: process.env.DB_PORT,
});

async function fixBookingConstraint() {
    const client = await pool.connect();
    try {
        console.log('Fixing booking status constraint...');
        console.log('Connection params:', {
            user: process.env.DB_USER,
            host: process.env.DB_HOST,
            database: process.env.DB_NAME,
            password: process.env.DB_PASSWORD ? '***' : 'undefined'
        });
        
        // Drop old constraint
        await client.query(`
            ALTER TABLE bookings
            DROP CONSTRAINT IF EXISTS bookings_status_check;
        `);
        console.log('✓ Old constraint dropped');

        // Add new constraint with paid_cash
        await client.query(`
            ALTER TABLE bookings
            ADD CONSTRAINT bookings_status_check
            CHECK (status IN ('pending','accepted','rejected','completed','paid_cash','cancelled'));
        `);
        console.log('✓ New constraint created with paid_cash status');

        // Verify
        const result = await client.query(`
            SELECT constraint_name, table_name
            FROM information_schema.table_constraints
            WHERE table_name = 'bookings' 
            AND constraint_type = 'CHECK'
            AND constraint_name = 'bookings_status_check';
        `);

        if (result.rows.length > 0) {
            console.log('✓ Constraint verified successfully');
            console.log(result.rows[0]);
        } else {
            console.log('✗ Constraint verification failed');
        }
    } catch (error) {
        console.error('Error fixing constraint:', error.message);
        throw error;
    } finally {
        client.release();
        await pool.end();
    }
}

fixBookingConstraint()
    .then(() => {
        console.log('✓ Booking constraint fixed!');
        process.exit(0);
    })
    .catch(error => {
        console.error('✗ Failed to fix constraint:', error.message);
        process.exit(1);
    });
