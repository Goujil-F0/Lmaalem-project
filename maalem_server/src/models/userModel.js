const pool = require('./db');

const createUser = async (full_name, email, password_hash, role, phone, city, neighborhood, latitude, longitude) => {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // 1. Créer le user
    const userResult = await client.query(
      `INSERT INTO users 
        (full_name, email, password_hash, role, phone, city, neighborhood, latitude, longitude)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
       RETURNING id, full_name, email, role, phone, city, neighborhood, latitude, longitude, profile_photo_url AS photo_url`,
      [full_name, email, password_hash, role, phone, city, neighborhood, latitude, longitude]
    );

    const user = userResult.rows[0];

    // 2. Si artisan → créer profil et le retourner
    let resultData = user;
    if (role === 'artisan') {
      await client.query(
        `INSERT INTO artisan_profiles (user_id, is_available) VALUES ($1, $2)`,
        [user.id, true]
      );
      const profileResult = await client.query(
        'SELECT * FROM artisan_profiles WHERE user_id = $1',
        [user.id]
      );
      resultData = {
        ...user,
        profile: profileResult.rows[0]
      };
    }

    await client.query('COMMIT');
    return resultData;

  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
};

const findUserByEmail = async (email) => {
  const result = await pool.query(
    'SELECT * FROM users WHERE email = $1',
    [email]
  );
  return result.rows[0];
};

module.exports = { createUser, findUserByEmail };
