const multer = require('multer');
const path = require('path');
const fs = require('fs');

// Créer le dossier uploads s'il n'existe pas
const uploadDir = 'uploads/cin';
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
}

const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    const side = file.fieldname; // cin_recto ou cin_verso
    const uniqueName = `${side}-${Date.now()}-${req.user.id}${path.extname(file.originalname)}`;
    cb(null, uniqueName);
  }
});

const fileFilter = (req, file, cb) => {
  const allowed = ['image/jpeg', 'image/png', 'image/jpg'];
  if (allowed.includes(file.mimetype)) {
    cb(null, true);
  } else {
    cb(new Error('Format non supporté. JPG ou PNG uniquement'), false);
  }
};

const uploadCin = multer({
  storage,
  fileFilter,
  limits: { fileSize: 5 * 1024 * 1024 } // 5MB max
}).fields([
  { name: 'cin_recto', maxCount: 1 },
  { name: 'cin_verso', maxCount: 1 }
]);

module.exports = { uploadCin };