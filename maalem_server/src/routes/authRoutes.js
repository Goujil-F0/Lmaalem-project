const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const { verifyToken } = require('../middleware/authMiddleware');

router.post('/register', authController.register);
router.post('/login', authController.login);

router.get('/test-protected', verifyToken, (req, res) => {
  res.json({ 
    message: `Bonjour ${req.user.email} !`, 
    role: req.user.role 
  });
});

module.exports = router;