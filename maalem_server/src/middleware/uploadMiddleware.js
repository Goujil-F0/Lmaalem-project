const fs = require('fs');
const multer = require('multer');
const path = require('path');

const uploadsRoot = path.join(__dirname, '..', '..', '..', 'uploads');
const uploadRoot = path.join(uploadsRoot, 'cin');
if (!fs.existsSync(uploadRoot)) {
  fs.mkdirSync(uploadRoot, { recursive: true });
}

const createStorage = (folder) => multer.diskStorage({
  destination: (req, file, cb) => {
    const userDir = path.join(uploadsRoot, folder, String(req.user.id));
    fs.mkdirSync(userDir, { recursive: true });
    cb(null, userDir);
  },
  filename: (req, file, cb) => {
    const uniqueName = `${file.fieldname}-${Date.now()}${path.extname(file.originalname)}`;
    cb(null, uniqueName);
  },
});

const fileFilter = (req, file, cb) => {
  const allowed = ['image/jpeg', 'image/png', 'image/jpg', 'application/pdf'];
  if (allowed.includes(file.mimetype)) {
    cb(null, true);
    return;
  }
  cb(new Error('Format non supporte. JPG, PNG ou PDF uniquement'), false);
};

const uploadCin = multer({
  storage: createStorage('cin'),
  fileFilter,
  limits: { fileSize: 5 * 1024 * 1024 },
}).fields([
  { name: 'cin_recto', maxCount: 1 },
  { name: 'cin_verso', maxCount: 1 },
]);

const uploadProfilePhoto = multer({
  storage: createStorage('profile'),
  fileFilter,
  limits: { fileSize: 5 * 1024 * 1024 },
}).single('profile_photo');

const uploadPortfolioImage = multer({
  storage: createStorage('portfolio'),
  fileFilter,
  limits: { fileSize: 5 * 1024 * 1024 },
}).single('portfolio_image');

module.exports = { uploadCin, uploadProfilePhoto, uploadPortfolioImage };
