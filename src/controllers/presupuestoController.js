const db = require('../models/init-associations');
const { Presupuesto, PresupuestoItem, Actividad } = db;
const { successResponse, errorResponse } = require('../utils/responseBuilder');
const { ROLES, STATUS, SUB_STATUS } = require('../utils/constants');

// @desc    Create a new budget for an activity
// @route   POST /api/actividades/:actividadId/presupuesto
// @access  Private/Productor
const createPresupuesto = async (req, res) => {
  const { actividadId } = req.params;
  const { total_cop, estado_presupuesto, comentario_global, items } = req.body;

  if (!total_cop || !items || items.length === 0) {
    return errorResponse(res, 'Total COP and at least one item are required', null, 400);
  }

  try {
    const actividad = await Actividad.findByPk(actividadId);
    if (!actividad) {
      return errorResponse(res, 'Activity not found', null, 404);
    }

    // RBAC: Productor AND Comercial can create/edit budget
    if (req.user.rol !== ROLES.PRODUCTOR && req.user.rol !== ROLES.COMERCIAL) {
      return errorResponse(res, 'Not authorized to create budget', null, 403);
    }

    const totalItems = items.reduce((sum, current) => sum + parseFloat(current.subtotal_cop || 0), 0);
    if (totalItems > parseFloat(actividad.valor_total)) {
      return errorResponse(res, `El presupuesto inicial (${totalItems}) excede el valor total de la actividad (${actividad.valor_total}).`, null, 400);
    }

    // Check if budget already exists for this activity
    const existingPresupuesto = await Presupuesto.findOne({ where: { actividad_id: actividadId } });
    if (existingPresupuesto) {
      return errorResponse(res, 'Budget already exists for this activity. Use PUT to update.', null, 400);
    }

    const presupuesto = await Presupuesto.create({
      actividad_id: actividadId,
      total_cop,
      estado_presupuesto: estado_presupuesto || 'Pendiente',
      comentario_global,
    });

    const presupuestoItems = items.map(item => ({
      presupuesto_id: presupuesto.id,
      ...item,
    }));

    await PresupuestoItem.bulkCreate(presupuestoItems);

    // Update activity status if applicable
    if (actividad.status === STATUS.PLANIFICACION && actividad.sub_status === SUB_STATUS.BORRADOR) {
      await actividad.update({ sub_status: SUB_STATUS.EN_REVISION });
    }

    successResponse(res, 'Budget created successfully', presupuesto, 201);
  } catch (error) {
    console.error(error);
    errorResponse(res, 'Server error', null, 500);
  }
};

// @desc    Get budget for an activity
// @route   GET /api/actividades/:actividadId/presupuesto
// @access  Private
const getPresupuestoByActividadId = async (req, res) => {
  const { actividadId } = req.params;

  try {
    const presupuesto = await Presupuesto.findOne({
      where: { actividad_id: actividadId },
      include: [{
        model: PresupuestoItem,
        as: 'PresupuestoItems',
      }],
    });

    if (!presupuesto) {
      // Return 200 with null data to avoid browser console 404 errors
      return successResponse(res, 'No budget found for this activity', null);
    }

    // RBAC: Check if user has access to the activity
    const actividad = await Actividad.findByPk(actividadId);
    if (!actividad) {
      return errorResponse(res, 'Activity not found', null, 404);
    }
    // SHARED VISIBILITY: Removed ownership check.
    /*
    if (req.user.rol === ROLES.COMERCIAL && actividad.comercial_id !== req.user.id) {
      return errorResponse(res, 'Not authorized to view this budget', null, 403);
    }
    */
    // Add more RBAC for Productor, Cliente, Admin

    successResponse(res, 'Budget fetched successfully', presupuesto);
  } catch (error) {
    console.error(error);
    errorResponse(res, 'Server error', null, 500);
  }
};

// @desc    Update budget details (total_cop, comentario_global)
// @route   PUT /api/v2/presupuestos/:id
// @access  Private/Productor
const updatePresupuesto = async (req, res) => {
  const { id } = req.params;
  const { total_cop, estado_presupuesto, comentario_global } = req.body;
  const ifMatch = req.headers['if-match'];

  try {
    const presupuesto = await Presupuesto.findByPk(id);
    if (!presupuesto) {
      return errorResponse(res, 'Budget not found', null, 404);
    }

    // Optimistic Concurrency Control
    if (ifMatch && ifMatch !== `"${new Date(presupuesto.updatedAt).getTime()}"`) {
      return errorResponse(res, 'Conflict: The resource has been modified since your last read. Please refresh and try again.', null, 409);
    }

    // RBAC: Productor AND Comercial can update budget
    if (req.user.rol !== ROLES.PRODUCTOR && req.user.rol !== ROLES.COMERCIAL) {
      return errorResponse(res, 'Not authorized to update budget', null, 403);
    }

    await presupuesto.update({ total_cop, estado_presupuesto, comentario_global });

    res.set('ETag', `"${new Date(presupuesto.updatedAt).getTime()}"`);
    successResponse(res, 'Budget updated successfully', presupuesto);
  } catch (error) {
    console.error(error);
    errorResponse(res, 'Server error', null, 500);
  }
};

// @desc    Add an item to a budget
// @route   POST /api/v2/presupuestos/:id/items
// @access  Private/Productor
const addPresupuestoItem = async (req, res) => {
  const { id } = req.params; // presupuesto_id
  const { item, cantidad, costo_unitario_cop, subtotal_cop, impuesto_cop, comentario } = req.body;

  if (!item || !cantidad || !costo_unitario_cop || !subtotal_cop) {
    return errorResponse(res, 'Item, quantity, unit cost, and subtotal are required', null, 400);
  }

  try {
    const presupuesto = await Presupuesto.findByPk(id);
    if (!presupuesto) {
      return errorResponse(res, 'Budget not found', null, 404);
    }

    // RBAC: Productor AND Comercial can add items
    if (req.user.rol !== ROLES.PRODUCTOR && req.user.rol !== ROLES.COMERCIAL) {
      return errorResponse(res, 'Not authorized to add budget items', null, 403);
    }

    // Validation: Sum of items cannot exceed activity's valor_total
    const actividad = await Actividad.findByPk(presupuesto.actividad_id);
    if (!actividad) {
      return errorResponse(res, "Parent activity not found", null, 404);
    }

    const currentItems = await PresupuestoItem.findAll({ where: { presupuesto_id: id } });
    const currentTotal = currentItems.reduce((sum, current) => sum + parseFloat(current.subtotal_cop), 0);
    const newTotal = currentTotal + parseFloat(subtotal_cop);

    console.log('--- DEBUG ADD BUDGET ITEM ---');
    console.log('Activity ID:', actividad.id);
    console.log('Activity Total Value:', actividad.valor_total);
    console.log('Current Items Count:', currentItems.length);
    console.log('Current Total Used:', currentTotal);
    console.log('New Item Subtotal:', subtotal_cop);
    console.log('New Calculated Total:', newTotal);
    console.log('Is New Total > Activity Total?', newTotal > parseFloat(actividad.valor_total));
    console.log('-----------------------------');

    if (newTotal > parseFloat(actividad.valor_total)) {
      return errorResponse(res, `Error de Presupuesto: El nuevo total calculado (${newTotal}) excede el valor total de la actividad (${actividad.valor_total}). Total actual en ítems: ${currentTotal}. Intenta aumentar el valor de la actividad.`, null, 400);
    }

    const newItem = await PresupuestoItem.create({
      presupuesto_id: id,
      item,
      cantidad,
      costo_unitario_cop,
      subtotal_cop,
      impuesto_cop,
      comentario,
    });

    successResponse(res, 'Budget item added successfully', newItem, 201);
  } catch (error) {
    console.error(error);
    errorResponse(res, 'Server error', null, 500);
  }
};

// @desc    Update a budget item
// @route   PUT /api/v2/presupuestos/items/:itemId
// @access  Private/Productor
const updatePresupuestoItem = async (req, res) => {
  const { itemId } = req.params;
  const updates = req.body;
  const ifMatch = req.headers['if-match'];

  try {
    const item = await PresupuestoItem.findByPk(itemId);
    if (!item) {
      return errorResponse(res, 'Budget item not found', null, 404);
    }

    // Optimistic Concurrency Control
    if (ifMatch && ifMatch !== `"${new Date(item.updatedAt).getTime()}"`) {
      return errorResponse(res, 'Conflict: The resource has been modified since your last read. Please refresh and try again.', null, 409);
    }

    const presupuesto = await Presupuesto.findByPk(item.presupuesto_id);
    // RBAC: Productor AND Comercial can update items
    if (req.user.rol !== ROLES.PRODUCTOR && req.user.rol !== ROLES.COMERCIAL) {
      return errorResponse(res, 'Not authorized to update budget items', null, 403);
    }

    await item.update(updates);

    res.set('ETag', `"${new Date(item.updatedAt).getTime()}"`);
    successResponse(res, 'Budget item updated successfully', item);
  } catch (error) {
    console.error(error);
    errorResponse(res, 'Server error', null, 500);
  }
};

// @desc    Delete a budget item
// @route   DELETE /api/presupuestos/items/:itemId
// @access  Private/Productor
const deletePresupuestoItem = async (req, res) => {
  const { itemId } = req.params;

  try {
    const item = await PresupuestoItem.findByPk(itemId);
    if (!item) {
      return errorResponse(res, 'Budget item not found', null, 404);
    }

    const presupuesto = await Presupuesto.findByPk(item.presupuesto_id);
    // RBAC: Productor AND Comercial can delete items
    if (req.user.rol !== ROLES.PRODUCTOR && req.user.rol !== ROLES.COMERCIAL) {
      return errorResponse(res, 'Not authorized to delete budget items', null, 403);
    }

    await item.destroy();
    successResponse(res, 'Budget item deleted successfully');
  } catch (error) {
    console.error(error);
    errorResponse(res, 'Server error', null, 500);
  }
};

const fileService = require('../services/fileService');

// @desc    Upload OC document
// @route   POST /api/v2/presupuestos/:id/oc
// @access  Private/Cliente
const uploadOC = async (req, res) => {
  const { id } = req.params;

  if (!req.file) {
    return errorResponse(res, 'No file uploaded', null, 400);
  }

  try {
    const presupuesto = await Presupuesto.findByPk(id, {
      include: [{
        model: Actividad,
        include: [{ model: db.Proyecto, include: [{ model: db.User, as: 'Cliente' }] }]
      }]
    });

    if (!presupuesto) {
      return errorResponse(res, 'Budget not found', null, 404);
    }

    // RBAC: Only Cliente can upload OC
    if (req.user.rol !== ROLES.CLIENTE) {
      return errorResponse(res, 'Solo el Cliente puede cargar la Orden de Compra (OC)', null, 403);
    }

    // Optional: Verify if the user is the specific client for this project
    // const clienteProyecto = presupuesto.Actividad.Proyecto?.Cliente;
    // if (!clienteProyecto || clienteProyecto.id !== req.user.id) { ... }

    const fileData = await fileService.saveFile(req.file, presupuesto.actividad_id, 'documentos');

    presupuesto.archivo_oc = fileData.archivo_path; // Or store full object if needed, but path is usually enough
    await presupuesto.save();

    successResponse(res, 'Orden de Compra cargada exitosamente', { archivo_oc: presupuesto.archivo_oc });
  } catch (error) {
    console.error(error);
    errorResponse(res, 'Server error uploading OC', null, 500);
  }
};

module.exports.createPresupuesto = createPresupuesto;
module.exports.getPresupuestoByActividadId = getPresupuestoByActividadId;
module.exports.updatePresupuesto = updatePresupuesto;
module.exports.addPresupuestoItem = addPresupuestoItem;
module.exports.updatePresupuestoItem = updatePresupuestoItem;
module.exports.deletePresupuestoItem = deletePresupuestoItem;
module.exports.uploadOC = uploadOC;

