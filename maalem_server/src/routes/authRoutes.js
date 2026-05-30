const express = require('express');
const authController = require('../controllers/authController');
const { verifyToken, verifyArtisan } = require('../middleware/authMiddleware');
const {
  uploadCin,
  uploadProfilePhoto,
  uploadPortfolioImage,
} = require('../middleware/uploadMiddleware');

const router = express.Router();

router.post('/register', authController.register);
router.post('/login', authController.login);
router.post('/upload-cin', verifyToken, verifyArtisan, uploadCin, authController.uploadCinHandler);
router.post('/profile/photo', verifyToken, uploadProfilePhoto, authController.uploadProfilePhotoHandler);
router.post('/artisan/portfolio', verifyToken, verifyArtisan, uploadPortfolioImage, authController.uploadPortfolioHandler);
router.patch('/availability', verifyToken, verifyArtisan, authController.updateAvailability);
router.patch('/profile', verifyToken, authController.updateClientProfile);
router.patch('/artisan/profile', verifyToken, verifyArtisan, authController.updateArtisanProfile);

router.get('/test-protected', verifyToken, (req, res) => {
  res.json({
    message: `Bonjour ${req.user.email} !`,
    role: req.user.role,
  });
});

module.exports = router;
