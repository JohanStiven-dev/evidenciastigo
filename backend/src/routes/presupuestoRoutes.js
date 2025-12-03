const express = require('express');
const router = express.Router();
const { getPresupuestoByActividadId, updatePresupuesto, addPresupuestoItem, updatePresupuestoItem, deletePresupuestoItem, uploadOC } = require('../controllers/presupuestoController');
const { protect, authorize } = require('../middleware/authMiddleware');
const { uploadSingle } = require('../middleware/uploadMiddleware');
const { ROLES } = require('../utils/constants');

// New route to get budget by actividadId
router.route('/actividad/:actividadId')
  .get(protect, getPresupuestoByActividadId);

// Routes for updating budget (total, global comment)
router.route('/:id')
  .put(protect, authorize(ROLES.COMERCIAL), updatePresupuesto);

// Route for uploading OC (Orden de Compra) - Only Cliente
router.route('/:id/oc')
  .post(protect, authorize(ROLES.CLIENTE), uploadSingle, uploadOC);

// Routes for budget items
router.route('/:id/items') // :id here refers to presupuesto_id
  .post(protect, authorize(ROLES.COMERCIAL), addPresupuestoItem);

router.route('/items/:itemId')
  .put(protect, authorize(ROLES.COMERCIAL), updatePresupuestoItem)
  .delete(protect, authorize(ROLES.COMERCIAL), deletePresupuestoItem);

module.exports = router;