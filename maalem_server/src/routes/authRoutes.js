const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const { verifyToken, verifyArtisan } = require('../middleware/authMiddleware');
const { uploadCin } = require('../middleware/uploadMiddleware');

router.post('/register', authController.register);
router.post('/login', authController.login);
router.post('/upload-cin', verifyToken, verifyArtisan, uploadCin, authController.uploadCinHandler);


router.get('/test-protected', verifyToken, (req, res) => {
  res.json({ 
    message: `Bonjour ${req.user.email} !`, 
    role: req.user.role 
  });
});

module.exports = router;