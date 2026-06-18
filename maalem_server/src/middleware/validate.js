// middleware/validate.js

/**
 * Valide que les champs requis sont présents dans req.body.
 * Usage : router.post('/register', validate(['email', 'password', 'full_name']), authController.register)
 */
const validate = (requiredFields) => (req, res, next) => {
  const missing = requiredFields.filter((field) => !req.body[field]);

  if (missing.length > 0) {
    return res.status(400).json({
      success: false,
      error: `Champs manquants : ${missing.join(', ')}`,
    });
  }

  next();
};

module.exports = validate;