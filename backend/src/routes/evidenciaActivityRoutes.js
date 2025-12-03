const express = require('express');
const router = express.Router({ mergeParams: true }); // mergeParams to access :actividadId
const evidenciaController = require('../controllers/evidenciaController');
const { protect, authorize } = require('../middleware/authMiddleware');
const { uploadMiddleware } = require('../middleware/uploadMiddleware');
const { ROLES } = require('../utils/constants');

router.route('/:actividadId/evidencias')
  .post(protect, authorize(ROLES.PRODUCTOR), uploadMiddleware, evidenciaController.uploadEvidencias)
  .get(protect, evidenciaController.getEvidenciasByActividadId);

module.exports = router;
