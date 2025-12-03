const Bitacora = require('../models/BitacoraModel');
const User = require('../models/UserModel');
const Actividad = require('../models/ActividadModel'); // Import Actividad model for RBAC
const { successResponse, errorResponse } = require('../utils/responseBuilder');
const { getQueryOptions, buildPaginatedResponse } = require('../utils/queryFeatures');
const { ROLES } = require('../utils/constants');

// @desc    Get audit log for a specific activity
// @route   GET /api/bitacora/:actividadId
// @access  Private
const getBitacoraByActividadId = async (req, res) => {
  const { actividadId } = req.params;
  const user = req.user;

  const allowedFilters = ['accion', 'desde_estado', 'hacia_estado'];
  const allowedSorts = ['createdAt', 'accion'];

  const { page, per_page, options } = getQueryOptions(req.query, {
    allowedFilters,
    allowedSorts,
    defaultWhere: { actividad_id: actividadId }
  });

  try {
    // RBAC: Ensure user can view the activity associated with this log
    const actividad = await Actividad.findByPk(actividadId);
    if (!actividad) {
      return errorResponse(res, 'Actividad no encontrada', null, 404);
    }

    // Only Admin can view all logs
    // Comercial can view logs for their activities
    // Productor can view logs for activities they are assigned to
    // SHARED VISIBILITY: Removed ownership checks.
    /*
    if (user.rol === ROLES.COMERCIAL && actividad.comercial_id !== user.id) {
      return errorResponse(res, 'No autorizado para ver la bitácora de esta actividad', null, 403);
    }
    if (user.rol === ROLES.PRODUCTOR && actividad.productor_id !== user.id) {
      return errorResponse(res, 'No autorizado para ver la bitácora de esta actividad', null, 403);
    }
    */
    // Admin and other roles (if any) can view

    const logs = await Bitacora.findAndCountAll({
      ...options,
      include: [{
        model: User,
        attributes: ['id', 'nombre', 'email'],
      }],
    });

    const paginatedResponse = buildPaginatedResponse(logs, page, per_page);
    successResponse(res, 'Audit logs fetched successfully', paginatedResponse);
  } catch (error) {
    errorResponse(res, `Server error: ${error.message}`);
  }
};

module.exports = {
  getBitacoraByActividadId,
};
