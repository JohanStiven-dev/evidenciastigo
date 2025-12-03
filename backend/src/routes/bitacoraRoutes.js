const express = require('express');
const router = express.Router();
const bitacoraController = require('../controllers/bitacoraController');
const { protect } = require('../middleware/authMiddleware');

router.route('/actividad/:actividadId')
  .get(protect, bitacoraController.getBitacoraByActividadId);

module.exports = router;
