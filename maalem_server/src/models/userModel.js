const pool = require('./db');

// Créer un utilisateur
const createUser = async (full_name, email, password_hash, role, phone, city, neighborhood, latitude, longitude) => {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // 1. Créer le user
    const userResult = await client.query(
      `INSERT INTO users 
        (full_name, email, password_hash, role, phone, city, neighborhood, latitude, longitude)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
       RETURNING id, full_name, email, role, city, neighborhood`,
      [full_name, email, password_hash, role, phone, city, neighborhood, latitude, longitude]
    );

    const user = userResult.rows[0];

    // 2. Si artisan → créer automatiquement son profil
    if (role === 'artisan') {
      await client.query(
        `INSERT INTO artisan_profiles (user_id) VALUES ($1)`,
        [user.id]
      );
    }

    await client.query('COMMIT');
    return user;

  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
};

// Trouver par email
const findUserByEmail = async (email) => {
  const result = await pool.query(
    'SELECT * FROM users WHERE email = $1',
    [email]
  );
  return result.rows[0];
};

module.exports = { createUser, findUserByEmail };