const express = require('express');
const router = express.Router();
const dashboardController = require('../controllers/dashboardController'); // Reusing dashboardController for now
const { protect, authorize } = require('../middleware/authMiddleware');
const { ROLES } = require('../utils/constants');

router.route('/actividades.xlsx')
  .get(protect, authorize( ROLES.CLIENTE, ROLES.COMERCIAL), dashboardController.getActivitiesReportXLSX);

router.route('/presupuestos.csv')
  .get(protect, authorize( ROLES.CLIENTE), dashboardController.getPresupuestosReportCSV);

router.route('/actividad/:id/evidencias.zip')
  .get(protect, authorize( ROLES.CLIENTE, ROLES.COMERCIAL, ROLES.PRODUCTOR), dashboardController.getEvidenciasZipByActividadId);

module.exports = router;
