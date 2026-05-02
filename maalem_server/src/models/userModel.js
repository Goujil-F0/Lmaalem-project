const pool = require('./db');

const createUser = async (full_name, email, password_hash, role, phone, city, neighborhood, latitude, longitude) => {
  const result = await pool.query(
    `INSERT INTO users 
      (full_name, email, password_hash, role, phone, city, neighborhood, latitude, longitude)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
     RETURNING id, full_name, email, role, city, neighborhood`,
    [full_name, email, password_hash, role, phone, city, neighborhood, latitude, longitude]
  );
  return result.rows[0];
};

const findUserByEmail = async (email) => {
  const result = await pool.query(
    'SELECT * FROM users WHERE email = $1',
    [email]
  );
  return result.rows[0];
};

module.exports = { createUser, findUserByEmail };