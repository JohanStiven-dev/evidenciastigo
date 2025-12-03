const {
  Evidencia,
  Actividad,
  Presupuesto,
  PresupuestoItem,
  User,
  Bitacora
} = require('../models/init-associations');
const { successResponse, errorResponse } = require('../utils/responseBuilder');
const { ROLES } = require('../utils/constants');
const fileService = require('../services/fileService');
const notificationService = require('../services/notificationService');
const { notifyEvidenceUploaded, notifyEvidenceRejected, notifyActivityFinalized } = require('../services/notificationService');
const { Proyecto } = require('../models/init-associations');

const uploadEvidencias = async (req, res) => {
  const { actividadId } = req.params;
  const { presupuesto_item_id, tipo, comentario } = req.body;
  if (!req.files || req.files.length === 0) return errorResponse(res, 'No files uploaded', null, 400);
  if (!presupuesto_item_id) return errorResponse(res, 'presupuesto_item_id is required', null, 400);
  try {
    const pItem = await PresupuestoItem.findByPk(presupuesto_item_id, { include: [{ model: Presupuesto, where: { actividad_id: actividadId } }] });
    if (!pItem) return errorResponse(res, 'Presupuesto Item not found or does not belong to the specified activity', null, 404);
    const accessCheck = await checkEvidenceAccess(req, res, { presupuesto_item_id });
    if (!accessCheck.authorized) return errorResponse(res, accessCheck.message, null, 403);
    const savedFiles = await Promise.all(req.files.map(file => fileService.saveFile(file, actividadId, tipo || 'image')));
    const evidencias = await Evidencia.bulkCreate(savedFiles.map(fileData => ({ presupuesto_item_id, tipo: fileData.tipo || 'image', archivo_path: fileData.archivo_path, archivo_nombre: fileData.archivo_nombre, mime: fileData.mime, peso_bytes: fileData.peso_bytes, comentario })));
    successResponse(res, 'Evidences uploaded successfully', evidencias, 201);
  } catch (error) {
    console.error(error);
    errorResponse(res, 'Server error while uploading evidences', null, 500);
  }
};

const getEvidenciasByActividadId = async (req, res) => {
  const { actividadId } = req.params;
  try {
    const presupuesto = await Presupuesto.findOne({
      where: { actividad_id: actividadId },
      include: [{
        model: PresupuestoItem,
        include: [{ model: Evidencia }]
      }]
    });

    if (!presupuesto) {
      // It's valid to have no budget yet, so no evidences
      return successResponse(res, 'No evidences found (no budget)', []);
    }

    if (!presupuesto.PresupuestoItems) {
      return successResponse(res, 'No evidences found (no budget items)', []);
    }

    const allEvidencias = presupuesto.PresupuestoItems.flatMap(item => item.Evidencias || []);

    if (allEvidencias.length > 0) {
      // Check access using the first evidence found
      // Note: This assumes all evidences in an activity belong to the same permission scope, which is true.
      const firstEvidence = allEvidencias[0];
      const accessCheck = await checkEvidenceAccess(req, res, { presupuesto_item_id: firstEvidence.presupuesto_item_id });

      if (!accessCheck.authorized) {
        return errorResponse(res, accessCheck.message, null, 403);
      }
    }

    successResponse(res, 'Evidences fetched successfully', allEvidencias.map(e => e.toJSON()));
  } catch (error) {
    console.error('Error fetching evidences by activity ID:', error);
    errorResponse(res, `Server error while fetching evidences: ${error.message}`, null, 500);
  }
};

const checkEvidenceAccess = async (req, res, evidencia) => {
  try {
    const presupuestoItem = await PresupuestoItem.findByPk(evidencia.presupuesto_item_id, {
      include: [{
        model: Presupuesto,
        include: [{
          model: Actividad,
          attributes: ['id', 'comercial_id', 'productor_id', 'proyecto_id'],
          include: [{ model: Proyecto, include: [{ model: User, as: 'Cliente' }] }]
        }]
      }]
    });

    if (!presupuestoItem || !presupuestoItem.Presupuesto || !presupuestoItem.Presupuesto.Actividad) {
      return { authorized: false, message: 'No se pudo verificar el acceso a la evidencia (Relación no encontrada).' };
    }

    const actividad = presupuestoItem.Presupuesto.Actividad;
    const user = req.user;

    // Admin always has access
    if (user.rol === ROLES.ADMIN) return { authorized: true };

    // Comercial access (Shared)
    if (user.rol === ROLES.COMERCIAL) return { authorized: true };

    // Productor access (Shared)
    if (user.rol === ROLES.PRODUCTOR) return { authorized: true };

    // Cliente access
    if (user.rol === ROLES.CLIENTE) {
      const clienteProyecto = actividad.Proyecto?.Cliente;
      if (clienteProyecto && clienteProyecto.id === user.id) {
        return { authorized: true };
      }
    }

    return { authorized: false, message: `No autorizado para acceder a esta evidencia.` };
  } catch (error) {
    console.error('Error in checkEvidenceAccess:', error);
    return { authorized: false, message: 'Error interno al verificar permisos.' };
  }
};

const createEvidencia = async (req, res) => {
  console.log('--- CREATE EVIDENCIA START ---');
  console.log('Body:', req.body);
  console.log('File:', req.file);

  const { presupuesto_item_id, tipo, comentario } = req.body;

  if (!req.file) {
    console.log('ERROR: No file uploaded');
    return errorResponse(res, 'No file uploaded', null, 400);
  }
  if (!presupuesto_item_id) {
    console.log('ERROR: presupuesto_item_id is required');
    return errorResponse(res, 'presupuesto_item_id is required', null, 400);
  }

  try {
    const pItem = await PresupuestoItem.findByPk(presupuesto_item_id, {
      include: [{
        model: Presupuesto,
        include: [{
          model: Actividad,
          attributes: ['id', 'codigos', 'agencia', 'ciudad', 'fecha'],
          include: [{ model: Proyecto, include: [{ model: User, as: 'Cliente' }] }]
        }]
      }]
    });

    if (!pItem) {
      console.log('ERROR: Presupuesto Item not found');
      return errorResponse(res, 'Presupuesto Item not found', null, 404);
    }

    if (!pItem.Presupuesto || !pItem.Presupuesto.Actividad) {
      console.log('ERROR: Presupuesto or Actividad not found for this Item');
      return errorResponse(res, 'Invalid Presupuesto Item structure', null, 500);
    }

    const actividadIdForFolder = pItem.Presupuesto.Actividad.id;
    const accessCheck = await checkEvidenceAccess(req, res, { presupuesto_item_id });

    if (!accessCheck.authorized) {
      console.log('ERROR: Access denied:', accessCheck.message);
      return errorResponse(res, accessCheck.message, null, 403);
    }

    console.log('Saving file...');
    const fileData = await fileService.saveFile(req.file, actividadIdForFolder, tipo || 'image');
    console.log('File saved:', fileData);

    const evidencia = await Evidencia.create({
      presupuesto_item_id: presupuesto_item_id,
      tipo: fileData.tipo || 'image',
      archivo_path: fileData.archivo_path,
      archivo_nombre: fileData.archivo_nombre,
      mime: fileData.mime,
      peso_bytes: fileData.peso_bytes,
      comentario: comentario
    });

    console.log('Evidencia created:', evidencia.id);

    // Notify Client
    // Notify Client
    try {
      const actividad = pItem.Presupuesto.Actividad;
      const cliente = actividad.Proyecto?.Cliente;
      if (cliente) {
        await notifyEvidenceUploaded(actividad, cliente, pItem, evidencia.tipo);
      } else {
        console.log('WARNING: No client found to notify.');
      }
    } catch (notifyError) {
      console.error('WARNING: Failed to send notification:', notifyError);
      // Do not fail the request if notification fails
    }

    console.log('--- CREATE EVIDENCIA SUCCESS ---');
    return successResponse(res, 'Evidence created successfully', evidencia, 201);
  } catch (error) {
    console.error('--- CREATE EVIDENCIA ERROR ---');
    console.error('Error details:', error);
    console.error('Stack:', error.stack);
    return errorResponse(res, `Server error while creating evidence: ${error.message}`, null, 500);
  }
};

const getEvidenciasByPresupuestoItemId = async (req, res) => {
  const { presupuestoItemId } = req.params;
  try {
    const pItem = await PresupuestoItem.findByPk(presupuestoItemId, {
      include: [{
        model: Presupuesto,
        include: [{
          model: Actividad,
          attributes: ['id', 'comercial_id', 'productor_id'],
          include: [{ model: Proyecto, include: [{ model: User, as: 'Cliente' }] }]
        }]
      }]
    });
    if (!pItem) return errorResponse(res, 'Presupuesto Item not found', null, 404);
    const accessCheck = await checkEvidenceAccess(req, res, { presupuesto_item_id: presupuestoItemId });
    if (!accessCheck.authorized) return errorResponse(res, accessCheck.message, null, 403);
    const evidences = await Evidencia.findAll({ where: { presupuesto_item_id: presupuestoItemId } });
    const evidencesJson = evidences.map(e => e.toJSON());
    successResponse(res, 'Evidences fetched successfully', evidencesJson);
  } catch (error) {
    console.error(error);
    errorResponse(res, 'Server error', null, 500);
  }
};

const downloadEvidencia = async (req, res) => {
  const { id } = req.params;
  try {
    const evidencia = await Evidencia.findByPk(id);
    if (!evidencia) return errorResponse(res, 'Evidence not found', null, 404);
    // Access check removed for public download
    // const accessCheck = await checkEvidenceAccess(req, res, evidencia);
    // if (!accessCheck.authorized) return errorResponse(res, accessCheck.message, null, 403);

    const path = require('path');
    // Ensure path is relative to project root, removing leading slash if present
    const relativePath = evidencia.archivo_path.startsWith('/') ? evidencia.archivo_path.substring(1) : evidencia.archivo_path;
    const absolutePath = path.join(process.cwd(), relativePath);

    // Use res.sendFile to allow inline display (for Image.network)
    // res.download forces 'Content-Disposition: attachment' which might break image display
    res.sendFile(absolutePath, (err) => {
      if (err) {
        console.error('Error sending file:', err);
        if (!res.headersSent) {
          return errorResponse(res, 'Could not send file', null, 500);
        }
      }
    });
  } catch (error) {
    console.error(error);
    errorResponse(res, 'Server error', null, 500);
  }
};

const deleteEvidencia = async (req, res) => {
  const { id } = req.params;
  try {
    const evidencia = await Evidencia.findByPk(id);
    if (!evidencia) return errorResponse(res, 'Evidence not found', null, 404);
    const accessCheck = await checkEvidenceAccess(req, res, evidencia);
    if (!accessCheck.authorized) return errorResponse(res, accessCheck.message, null, 403);
    if (req.user.rol !== ROLES.PRODUCTOR) return errorResponse(res, 'Solo un Productor puede eliminar evidencias', null, 403);
    await fileService.deleteFile(evidencia.archivo_path);
    await evidencia.destroy();
    successResponse(res, 'Evidence deleted successfully');
  } catch (error) {
    console.error(error);
    errorResponse(res, 'Server error', null, 500);
  }
};

const updateEvidenciaStatus = async (req, res) => {
  const { id } = req.params;
  const { status, motivoRechazo } = req.body;
  if (!['aprobado', 'rechazado'].includes(status)) return errorResponse(res, 'Invalid status provided. Must be "aprobado" or "rechazado".', null, 400);
  if (status === 'rechazado' && !motivoRechazo) return errorResponse(res, 'A rejection reason (motivoRechazo) is required when rejecting evidence.', null, 400);
  try {
    const evidencia = await Evidencia.findByPk(id, {
      include: {
        model: PresupuestoItem,
        include: {
          model: Presupuesto,
          include: {
            model: Actividad,
            include: [
              { model: User, as: 'Comercial' },
              { model: User, as: 'Productor' },
              { model: Proyecto, include: [{ model: User, as: 'Cliente' }] }
            ]
          }
        }
      }
    });
    if (!evidencia) return errorResponse(res, 'Evidence not found', null, 404);

    // RBAC Check for Client
    if (req.user.rol === ROLES.CLIENTE) {
      const actividad = evidencia.PresupuestoItem.Presupuesto.Actividad;
      const clienteProyecto = actividad.Proyecto?.Cliente;
      if (!clienteProyecto || clienteProyecto.id !== req.user.id) {
        return errorResponse(res, 'No autorizado para gestionar esta evidencia', null, 403);
      }
    }
    const oldStatus = evidencia.status;
    if (oldStatus === status) return successResponse(res, 'Evidence status is already set to the desired state.', evidencia);
    evidencia.status = status;
    await evidencia.save();
    const actividad = evidencia.PresupuestoItem.Presupuesto.Actividad;
    await Bitacora.create({ actividad_id: actividad.id, user_id: req.user.id, accion: 'Validación de Evidencia', desde_estado: `Evidencia ID ${evidencia.id}: ${oldStatus}`, hacia_estado: `Evidencia ID ${evidencia.id}: ${status}`, motivo: status === 'rechazado' ? motivoRechazo : 'Evidencia aprobada', ip_address: req.ip });
    if (status === 'rechazado') {
      await notifyEvidenceRejected(actividad, evidencia, motivoRechazo, actividad.Productor);
    } else if (status === 'aprobado') {
      // Check if ALL evidences for this activity are approved
      const allEvidences = await Evidencia.findAll({
        include: {
          model: PresupuestoItem,
          required: true,
          include: {
            model: Presupuesto,
            required: true,
            where: { actividad_id: actividad.id }
          }
        }
      });

      const allApproved = allEvidences.every(e => e.status === 'aprobado');

      if (allApproved && allEvidences.length > 0) {
        // Update Activity Status to Finalizada
        const oldActivityStatus = `${actividad.status} - ${actividad.sub_status}`;
        actividad.status = 'Finalizada';
        actividad.sub_status = 'Completado';
        await actividad.save();

        // Log in Bitacora
        await Bitacora.create({
          actividad_id: actividad.id,
          user_id: req.user.id,
          accion: 'Finalización Automática',
          motivo: 'Todas las evidencias fueron aprobadas por el cliente.',
          desde_estado: oldActivityStatus,
          hacia_estado: 'Finalizada - Completado',
          ip_address: req.ip
        });

        await notifyActivityFinalized(actividad, actividad.Comercial, actividad.Productor, actividad.Proyecto?.Cliente);
      }
    }
    successResponse(res, 'Evidence status updated successfully', evidencia);
  } catch (error) {
    console.error('Error updating evidence status:', error);
    errorResponse(res, 'Server error while updating evidence status', null, 500);
  }
};

module.exports = {
  createEvidencia,
  getEvidenciasByPresupuestoItemId,
  downloadEvidencia,
  deleteEvidencia,
  uploadEvidencias,
  getEvidenciasByActividadId,
  updateEvidenciaStatus,
};
