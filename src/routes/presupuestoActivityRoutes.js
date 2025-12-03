const express = require('express');
const router = express.Router({ mergeParams: true }); // mergeParams to access :actividadId
const presupuestoController = require('../controllers/presupuestoController');
const { protect, authorize } = require('../middleware/authMiddleware');
const { ROLES } = require('../utils/constants');

router.route('/:actividadId/presupuesto')
  .post(protect, authorize(ROLES.PRODUCTOR), presupuestoController.createPresupuesto)
  .get(protect, presupuestoController.getPresupuestoByActividadId);

module.exports = router;
