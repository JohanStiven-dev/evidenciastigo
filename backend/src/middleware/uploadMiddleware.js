const multer = require('multer');
const path = require('path');
const { errorResponse } = require('../utils/responseBuilder');

// Set up storage engine
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    // Files are initially uploaded to a temporary directory
    // They will be moved to their final destination by fileService
    cb(null, path.join(__dirname, '../../temp_uploads'));
  },
  filename: (req, file, cb) => {
    cb(null, `${file.fieldname}-${Date.now()}${path.extname(file.originalname)}`);
  },
});

// Check file type
const checkFileType = (file, cb) => {
  // Allowed extensions
  const filetypes = /jpeg|jpg|png|gif|pdf|webp/;
  // Allowed MIME types (more comprehensive)
  const allowedMimes = [
    'image/jpeg',
    'image/jpg',
    'image/png',
    'image/gif',
    'image/webp',
    'application/pdf',
    'application/octet-stream' // Fallback for web uploads
  ];

  // Check extension
  const extname = filetypes.test(path.extname(file.originalname).toLowerCase());
  // Check MIME type
  const mimetype = allowedMimes.includes(file.mimetype);

  console.log('File validation:', {
    originalname: file.originalname,
    mimetype: file.mimetype,
    extname: extname,
    mimetypeValid: mimetype
  });

  if (mimetype && extname) {
    return cb(null, true);
  } else {
    cb(new Error('Solo se permiten archivos de imagen (JPEG, PNG, GIF, WebP) y PDF'));
  }
};

const upload = multer({
  storage: storage,
  limits: { fileSize: 1024 * 1024 * 5 }, // 5MB limit
  fileFilter: (req, file, cb) => {
    checkFileType(file, cb);
  },
}).array('evidencias', 10); // 'evidencias' is the field name, 10 is max files

const uploadSingle = multer({
  storage: storage,
  limits: { fileSize: 1024 * 1024 * 10 }, // 10MB limit
  fileFilter: (req, file, cb) => {
    checkFileType(file, cb);
  },
}).single('evidencia');

const uploadMiddleware = (req, res, next) => {
  upload(req, res, (err) => {
    if (err instanceof multer.MulterError) {
      // A Multer error occurred when uploading.
      return errorResponse(res, `Multer error: ${err.message}`, null, 400);
    } else if (err) {
      // An unknown error occurred when uploading.
      return errorResponse(res, `Upload error: ${err}`, null, 400);
    }
    next();
  });
};

module.exports = {
  uploadMiddleware,
  uploadSingle,
};
