const express = require('express');
const router = express.Router();
const actividadController = require('../controllers/actividadController');
const { protect, authorize } = require('../middleware/authMiddleware');
const { ROLES } = require('../utils/constants');

// Routes for /api/v2/actividades

router.route('/')
  .get(protect, actividadController.getAllActividades)
  .post(protect, authorize(ROLES.COMERCIAL), actividadController.createActividad);

router.route('/:id')
  .get(protect, actividadController.getActividadById)
  .put(protect, authorize(ROLES.COMERCIAL, ROLES.PRODUCTOR), actividadController.updateActividad);

router.route('/:id/status')
  .patch(protect, authorize(ROLES.COMERCIAL, ROLES.PRODUCTOR, ROLES.CLIENTE), actividadController.changeActividadStatus);

router.route('/:id/bitacora')
    .get(protect, actividadController.getActividadLogs);

// Dummy routes to prevent crashes if they are still being called from somewhere else.
// These should be properly implemented or removed later.
router.route('/:id/evidencias')
    .get(protect, actividadController.getEvidenciasByActividad)
    .post(protect, actividadController.uploadEvidenciaToActividad);

module.exports = router;