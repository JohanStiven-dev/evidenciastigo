const Catalogo = require('../models/CatalogoModel');
const { successResponse, errorResponse } = require('../utils/responseBuilder');

// @desc    Get all catalog values by type
// @route   GET /api/catalogo/:tipo
// @access  Private
const getCatalogoByType = async (req, res) => {
  try {
    const { tipo } = req.params;
    const catalogo = await Catalogo.findAll({ where: { tipo } });
    successResponse(res, 'Catalog fetched successfully', catalogo);
  } catch (error) {
    errorResponse(res, 'Server error', null, 500);
  }
};

module.exports = {
  getCatalogoByType,
};