const { Op } = require('sequelize');
const db = require('../models/init-associations');
const { successResponse, errorResponse } = require('../utils/responseBuilder');
const { getQueryOptions, buildPaginatedResponse } = require('../utils/queryFeatures');
const { addNotificationJob } = require('../services/queue');
const { BASE_URL_API } = require('../config/env');
const { ROLES, STATUS, SUB_STATUS } = require('../utils/constants');

const { Actividad, Bitacora, User, Notificacion, Presupuesto, PresupuestoItem, Evidencia } = db;
const sequelize = db.sequelize;

// @desc    Get all activities (with filters)
// @route   GET /api/v2/actividades
// @access  Private
const getAllActividades = async (req, res) => {
  const queryConfig = {
    allowedFilters: ['ciudad', 'canal', 'semana', 'status', 'sub_status', 'fecha_desde', 'fecha_hasta'],
    allowedSorts: ['createdAt', 'fecha', 'agencia', 'status', 'sub_status'],
    searchableFields: ['punto_venta', 'direccion', 'codigos', 'responsable_actividad'],
  };

  const { page, per_page, options } = getQueryOptions(req.query, queryConfig);

  // SHARED VISIBILITY: Removed user-specific filtering.
  // All users with the same role can see all activities (or filtered by other means if needed).
  /*
  if (req.user.rol === ROLES.COMERCIAL) {
    options.where.comercial_id = req.user.id;
  } else if (req.user.rol === ROLES.PRODUCTOR) {
    options.where.productor_id = req.user.id;
  }
  */

  try {
    const actividades = await Actividad.findAndCountAll({
      ...options,
      include: [
        { model: User, as: 'Comercial', attributes: ['id', 'nombre', 'email'] },
        { model: User, as: 'Productor', attributes: ['id', 'nombre', 'email'] },
      ],
    });

    const paginatedResponse = buildPaginatedResponse(actividades, page, per_page);
    successResponse(res, 'Activities fetched successfully', paginatedResponse);
  } catch (error) {
    errorResponse(res, `Server error: ${error.message}`);
  }
};

// @desc    Create a new activity
// @route   POST /api/v2/actividades
// @access  Private/Comercial
const createActividad = async (req, res) => {
  if (req.user.rol !== ROLES.COMERCIAL) {
    return errorResponse(res, 'Solo el rol Comercial puede crear actividades.', null, 403);
  }
  const t = await sequelize.transaction();
  try {
    const { ...activityData } = req.body;

    const newActivity = await Actividad.create({
      ...activityData,
      comercial_id: req.user.id,
      status: STATUS.PLANIFICACION,
      sub_status: SUB_STATUS.BORRADOR,
    }, { transaction: t });

    await Bitacora.create({
      actividad_id: newActivity.id,
      user_id: req.user.id,
      accion: 'Creación de Actividad',
      hacia_estado: `${STATUS.PLANIFICACION} - ${SUB_STATUS.BORRADOR}`,
      motivo: 'Actividad creada por Comercial.',
      ip_address: req.ip,
    }, { transaction: t });

    // Auto-create initial budget based on valor_total
    await Presupuesto.create({
      actividad_id: newActivity.id,
      total_cop: newActivity.valor_total,
      estado_presupuesto: 'Pendiente',
      comentario_global: 'Presupuesto inicial basado en valor total de actividad.',
    }, { transaction: t });

    await Bitacora.create({
      actividad_id: newActivity.id,
      user_id: req.user.id,
      accion: 'Creación de Presupuesto Inicial',
      motivo: 'Presupuesto auto-generado al crear actividad.',
      ip_address: req.ip,
    }, { transaction: t });

    await t.commit();

    // NOTE: Notification to client is now sent when moving to 'En Revisión'

    // NOTE: Notification is now sent only when moving to 'En Revisión' (Status Change)
    // notifyProducersNewActivity removed to comply with "only notify on status change" (Draft -> Review)

    successResponse(res, 'Activity created successfully', newActivity, 201);
  } catch (error) {
    await t.rollback();
    errorResponse(res, `Server error on activity creation: ${error.message}`);
  }
};

const {
  notifyActivityCreated,
  notifyActivityConfirmed,
  notifyActivityAssigned,
  notifyProducersNewActivity,
  notifyActivityCorrectionRequired,
  notifyEvidenceReadyForReview,
  notifyActivityFinalized,
  notifyEvidenceRejected
} = require('../services/notificationService');
const { Proyecto } = require('../models/init-associations');

// ... (existing imports)

const changeActividadStatus = async (req, res) => {
  const { id } = req.params;
  const { newStatus, newSubStatus, motivo } = req.body;
  const user = req.user;

  if (!newStatus || !newSubStatus) {
    return errorResponse(res, 'Los campos "newStatus" y "newSubStatus" son requeridos.', null, 400);
  }

  const t = await sequelize.transaction();
  try {
    const actividad = await Actividad.findByPk(id, {
      transaction: t,
      lock: true,
      include: [
        { model: User, as: 'Comercial' },
        { model: User, as: 'Productor' },
        { model: Proyecto, include: [{ model: User, as: 'Cliente' }] },
      ]
    });

    if (!actividad) {
      await t.rollback();
      return errorResponse(res, 'Actividad no encontrada', null, 404);
    }

    const oldStatus = actividad.status;
    const oldSubStatus = actividad.sub_status;

    const postCommitActions = [];

    // --- NEW WORKFLOW LOGIC ---

    // 1. Comercial sends to validation
    if (oldSubStatus === SUB_STATUS.BORRADOR && newSubStatus === SUB_STATUS.EN_REVISION && user.rol === ROLES.COMERCIAL) {
      postCommitActions.push(() => notifyActivityCreated(actividad));
    }

    // 2. Cliente approves/rejects initial proposal
    else if (oldSubStatus === SUB_STATUS.EN_REVISION && user.rol === ROLES.CLIENTE) {
      if (newSubStatus === SUB_STATUS.PROGRAMADA) { // Approved
        postCommitActions.push(() => notifyActivityConfirmed(actividad));
      } else if (newSubStatus === SUB_STATUS.RECHAZADO) { // Rejected
        postCommitActions.push(() => notifyActivityCorrectionRequired(actividad, motivo));
      }
    }

    // 3. Productor sends for final approval
    else if (oldSubStatus === SUB_STATUS.CARGANDO_EVIDENCIAS && newSubStatus === SUB_STATUS.APROBACION_FINAL && user.rol === ROLES.PRODUCTOR) {
      postCommitActions.push(() => notifyEvidenceReadyForReview(actividad));
    }

    // 4. Cliente gives final approval/rejection
    else if (oldSubStatus === SUB_STATUS.APROBACION_FINAL && user.rol === ROLES.CLIENTE) {
      if (newSubStatus === SUB_STATUS.COMPLETADO) { // Approved / Finalized
        postCommitActions.push(() => notifyActivityFinalized(actividad));

      } else if (newSubStatus === SUB_STATUS.CARGANDO_EVIDENCIAS) { // Rejected
        postCommitActions.push(() => notifyEvidenceRejected(actividad, null, motivo));
      }
    }

    // --- END OF NEW WORKFLOW ---


    actividad.status = newStatus;
    actividad.sub_status = newSubStatus;
    await actividad.save({ transaction: t });

    await Bitacora.create({
      actividad_id: id,
      user_id: user.id,
      accion: 'Cambio de Estado',
      desde_estado: `${oldStatus} - ${oldSubStatus}`,
      hacia_estado: `${newStatus} - ${newSubStatus}`,
      motivo: motivo,
      ip_address: req.ip,
    }, { transaction: t });

    await t.commit();

    // Execute post-commit actions (notifications)
    for (const action of postCommitActions) {
      try {
        await action();
      } catch (err) {
        console.error('Error executing post-commit action:', err);
        // Do not fail the request if notification fails, as the transaction is already committed
      }
    }

    successResponse(res, 'Estado de la actividad actualizado correctamente', actividad);
  } catch (error) {
    await t.rollback();
    errorResponse(res, `Error en el servidor al actualizar estado: ${error.message}`);
  }
};

// @desc    Get single activity by ID
// @route   GET /api/v2/actividades/:id
// @access  Private
const getActividadById = async (req, res) => {
  try {
    const actividad = await Actividad.findByPk(req.params.id, {
      include: [
        { model: User, as: 'Comercial', attributes: ['id', 'nombre', 'email'] },
        { model: User, as: 'Productor', attributes: ['id', 'nombre', 'email'] },
        {
          model: Presupuesto,
          as: 'Presupuesto',
          include: [{
            model: PresupuestoItem,
            include: [{ model: Evidencia }]
          }]
        },
      ],
    });

    if (!actividad) {
      return errorResponse(res, 'Activity not found', null, 404);
    }

    // SHARED VISIBILITY: Removed ownership checks.
    /*
    if (req.user.rol === ROLES.COMERCIAL && actividad.comercial_id !== req.user.id) {
      return errorResponse(res, 'Not authorized to view this activity', null, 403);
    }
    if (req.user.rol === ROLES.PRODUCTOR && actividad.productor_id !== req.user.id) {
      return errorResponse(res, 'Not authorized to view this activity', null, 403);
    }
    */

    successResponse(res, 'Activity fetched successfully', actividad);
  } catch (error) {
    errorResponse(res, `Server error: ${error.message}`);
  }
};

// @desc    Update an activity
// @route   PUT /api/v2/actividades/:id
// @access  Private
const updateActividad = async (req, res) => {
  const { id } = req.params;
  const { ...updates } = req.body;
  const ifMatch = req.headers['if-match'];
  const t = await sequelize.transaction();

  try {
    const actividad = await Actividad.findByPk(id, { transaction: t, lock: true });

    if (!actividad) {
      await t.rollback();
      return errorResponse(res, 'Activity not found', null, 404);
    }

    if (ifMatch && ifMatch !== `"${new Date(actividad.updatedAt).getTime()}"`) {
      await t.rollback();
      return errorResponse(res, 'Conflict: The resource has been modified since your last read. Please refresh and try again.', null, 409);
    }

    await actividad.update(updates, { transaction: t });

    await Bitacora.create({
      actividad_id: actividad.id,
      user_id: req.user.id,
      accion: 'Actualización de Actividad',
      motivo: 'Campos generales actualizados',
      ip_address: req.ip,
    }, { transaction: t });

    await t.commit();

    res.set('ETag', `"${new Date(actividad.updatedAt).getTime()}"`);
    successResponse(res, 'Activity updated successfully', actividad);
  } catch (error) {
    await t.rollback();
    errorResponse(res, `Server error: ${error.message}`);
  }
};

// @desc    Get activity logs
// @route   GET /api/v2/actividades/:id/bitacora
// @access  Private
const getActividadLogs = async (req, res) => {
  try {
    const { id } = req.params;
    const logs = await Bitacora.findAll({
      where: { actividad_id: id },
      order: [['createdAt', 'DESC']],
      include: [{ model: User, attributes: ['nombre', 'rol'] }]
    });
    successResponse(res, 'Logs fetched successfully', logs);
  } catch (error) {
    errorResponse(res, 'Server error', null, 500, error);
  }
};

// Dummy functions to avoid more errors for now
const getEvidenciasByActividad = async (req, res) => {
  successResponse(res, 'OK', []);
};
const uploadEvidenciaToActividad = async (req, res) => {
  successResponse(res, 'OK', {});
};

module.exports = {
  getAllActividades,
  createActividad,
  getActividadById,
  updateActividad,
  changeActividadStatus,
  getActividadLogs,
  getEvidenciasByActividad,
  uploadEvidenciaToActividad,
};