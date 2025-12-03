const express = require('express');
const router = express.Router();
const notificacionController = require('../controllers/notificacionController');
const { protect, authorize } = require('../middleware/authMiddleware');
const { ROLES } = require('../utils/constants');

router.route('/')
  .get(protect, notificacionController.getMyNotifications);


router.route('/:id/leido')
  .patch(protect, notificacionController.markAsRead);

router.route('/:id')
  .delete(protect, notificacionController.deleteNotification);

module.exports = router;
