const { Pool } = require('pg');
const path = require('path');
require('dotenv').config({ path: path.resolve(__dirname, '../../../.env') });

const pool = new Pool({
  host: process.env.DB_HOST,
  port: process.env.DB_PORT,
  database: process.env.DB_NAME,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
});

pool.connect()
  .then(async (client) => {
    try {
      await client.query(
        'ALTER TABLE users ADD COLUMN IF NOT EXISTS profile_photo_url TEXT'
      );
      await client.query(
        'ALTER TABLE messages ADD COLUMN IF NOT EXISTS is_read BOOLEAN DEFAULT FALSE'
      );
      console.log('Connecte a PostgreSQL');
    } finally {
      client.release();
    }
  })
  .catch((err) => console.error('Erreur PostgreSQL :', err.message));

module.exports = pool;
