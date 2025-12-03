const express = require('express');
const router = express.Router();
const { getEvidenciasByPresupuestoItemId, downloadEvidencia, deleteEvidencia, createEvidencia, updateEvidenciaStatus, getEvidenciasByActividadId } = require('../controllers/evidenciaController');
const { protect, authorize } = require('../middleware/authMiddleware');
const { uploadSingle } = require('../middleware/uploadMiddleware');
const { ROLES } = require('../utils/constants');

router.route('/')
  .post(protect, uploadSingle, createEvidencia);

router.route('/presupuesto-item/:presupuestoItemId')
  .get(protect, getEvidenciasByPresupuestoItemId);

router.route('/:id/status')
  .put(protect, authorize(ROLES.CLIENTE, ROLES.ADMIN), updateEvidenciaStatus);

router.route('/:id/download')
  .get(downloadEvidencia);

router.route('/:id')
  .delete(protect, authorize(ROLES.PRODUCTOR), deleteEvidencia);

router.route('/actividad/:actividadId')
  .get(protect, getEvidenciasByActividadId);

module.exports = router;