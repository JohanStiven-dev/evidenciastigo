const express = require('express');
const router = express.Router();
const dashboardController = require('../controllers/dashboardController');
const { protect, authorize } = require('../middleware/authMiddleware');
const { ROLES } = require('../utils/constants');

router.route('/resumen')
  .get(protect, dashboardController.getDashboardSummary);

// Other dashboard routes (e.g., by canal, by ciudad, by estado) can be added here

module.exports = router;