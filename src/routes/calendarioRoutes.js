const express = require('express');
const router = express.Router();
const calendarioController = require('../controllers/calendarioController');
const { protect } = require('../middleware/authMiddleware');

router.route('/')
  .get(protect, calendarioController.getCalendarioEvents);

router.route('/:actividadId/ical')
  .get(protect, calendarioController.exportIcal);

router.route('/usuario/:userId.ics')
  .get(protect, calendarioController.exportUserIcalFeed);

module.exports = router;
