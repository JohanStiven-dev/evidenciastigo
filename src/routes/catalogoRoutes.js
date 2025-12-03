const express = require('express');
const router = express.Router();
const catalogoController = require('../controllers/catalogoController');
const { protect, authorize } = require('../middleware/authMiddleware');
const { ROLES } = require('../utils/constants');

router
  .route('/:tipo')
  .get(protect, catalogoController.getCatalogoByType);

module.exports = router;
