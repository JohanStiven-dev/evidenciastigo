const Notificacion = require('../models/NotificacionModel');
const User = require('../models/UserModel');
const mailService = require('./mailService');


const { addNotificationJob } = require('./queue');
const { BASE_URL_API } = require('../config/env');

const createNotification = async (userId, actividadId, tipoEvento, canal, payload) => {
  try {
    const notification = await Notificacion.create({
      user_id: userId,
      actividad_id: actividadId,
      tipo_evento: tipoEvento,
      canal,
      payload,
      estado: 'pendiente',
    });

    if (canal === 'email') {
      const user = await User.findByPk(userId);
      if (user && user.email) {
        // DIRECT SEND: Bypassing queue to avoid Redis dependency issues
        try {
          await mailService.sendEmail(
            user.email,
            payload.subject,
            payload.templateName,
            payload.context
          );
          // Update notification status
          await notification.update({ estado: 'enviado', enviado_at: new Date() });
        } catch (emailError) {
          console.error('Error sending email directly:', emailError);
          await notification.update({ estado: 'fallido', error_msg: emailError.message });
        }
      }
    }

    return notification;
  } catch (error) {
    console.error('Error creating or sending notification:', error);
  }
};

const notifyAllUsersWithRole = async (role, subject, templateName, context) => {
  try {
    const users = await User.findAll({ where: { rol: role } });
    if (!users.length) return;

    const emailPromises = users.map(user => {
      // Personalize context with user name if needed, or keep generic
      const userContext = { ...context, userName: user.nombre };

      return createNotification(user.id, context.activityId, context.eventType, 'email', {
        subject,
        templateName,
        context: userContext
      });
    });

    await Promise.all(emailPromises);
  } catch (error) {
    console.error(`Error notifying role ${role}:`, error);
  }
};

// Helper to wrap createNotification logic inside the loop, reusing existing createNotification function
// But wait, createNotification handles the DB creation AND sending.
// Let's use the existing createNotification but call it for each user found.

const notifyActivityCreated = async (actividad) => {
  // Notify ALL Clients
  const context = {
    activityId: actividad.id,
    eventType: 'actividad_creada',
    activityCodigos: actividad.codigos,
    activityAgencia: actividad.agencia,
    activityCiudad: actividad.ciudad,
    activityFecha: actividad.fecha,
    activityLink: `${BASE_URL_API}/actividades/${actividad.id}`,
  };

  await notifyAllUsersWithRole('Cliente', `Nueva Actividad Creada: ${actividad.codigos}`, 'activityCreated', context);
};

const notifyActivityConfirmed = async (actividad) => {
  const context = {
    activityId: actividad.id,
    eventType: 'actividad_confirmada',
    activityCodigos: actividad.codigos,
    activityAgencia: actividad.agencia,
    activityCiudad: actividad.ciudad,
    activityFecha: actividad.fecha,
    activityLink: `${BASE_URL_API}/actividades/${actividad.id}`,
  };

  // Notify ALL Commercials and ALL Producers
  await notifyAllUsersWithRole('Comercial', `Actividad Aprobada: ${actividad.codigos}`, 'activityConfirmed', context);
  await notifyAllUsersWithRole('Productor', `Actividad Aprobada: ${actividad.codigos}`, 'activityConfirmed', context);
};

const notifyEvidenceUploaded = async (actividad, item, tipo) => {
  const context = {
    activityId: actividad.id,
    eventType: 'evidencia_subida',
    activityCodigos: actividad.codigos,
    itemName: item.item,
    evidenceType: tipo,
    activityLink: `${BASE_URL_API}/actividades/${actividad.id}`,
  };

  // Notify ALL Commercials and ALL Clients
  await notifyAllUsersWithRole('Comercial', `Nueva Evidencia Cargada: ${actividad.codigos}`, 'evidenceUploaded', context);
  await notifyAllUsersWithRole('Cliente', `Nueva Evidencia Cargada: ${actividad.codigos}`, 'evidenceUploaded', context);
};

const notifyEvidenceRejected = async (actividad, evidencia, motivo) => {
  let itemName = 'Item desconocido';
  if (evidencia && evidencia.PresupuestoItem) {
    itemName = evidencia.PresupuestoItem.item;
  }

  const context = {
    activityId: actividad.id,
    eventType: 'evidencia_rechazada',
    activityCodigos: actividad.codigos,
    itemName: itemName,
    rejectionReason: motivo,
    activityLink: `${BASE_URL_API}/actividades/${actividad.id}`,
  };

  // Notify ALL Producers and ALL Commercials
  await notifyAllUsersWithRole('Productor', `Evidencia Rechazada: ${actividad.codigos}`, 'evidenceRejected', context);
  await notifyAllUsersWithRole('Comercial', `Evidencia Rechazada: ${actividad.codigos}`, 'evidenceRejected', context);
};

const notifyActivityFinalized = async (actividad) => {
  const context = {
    activityId: actividad.id,
    eventType: 'actividad_finalizada',
    activityCodigos: actividad.codigos,
    activityAgencia: actividad.agencia,
    activityCiudad: actividad.ciudad,
    activityFecha: actividad.fecha,
    activityLink: `${BASE_URL_API}/actividades/${actividad.id}`,
  };

  // Notify ALL Commercials, ALL Producers, ALL Clients
  await notifyAllUsersWithRole('Comercial', `Actividad Finalizada: ${actividad.codigos}`, 'activityFinalized', context);
  await notifyAllUsersWithRole('Productor', `Actividad Finalizada: ${actividad.codigos}`, 'activityFinalized', context);
  await notifyAllUsersWithRole('Cliente', `Actividad Finalizada: ${actividad.codigos}`, 'activityFinalized', context);
};

const notifyActivityAssigned = async (actividad) => {
  // This event "Assigned" usually implies a specific person, but if we follow the rule:
  // Maybe "New Activity Available" covers this?
  // User said "notify all users with the same role".
  // If this is triggered when assigned, maybe we notify ALL Producers that it has been assigned?
  // Or maybe this event is redundant if we have "New Activity Available".
  // Let's keep it but broadcast to ALL Producers.

  const context = {
    activityId: actividad.id,
    eventType: 'actividad_asignada',
    activityCodigos: actividad.codigos,
    activityAgencia: actividad.agencia,
    activityCiudad: actividad.ciudad,
    activityFecha: actividad.fecha,
    activityLink: `${BASE_URL_API}/actividades/${actividad.id}`,
  };

  await notifyAllUsersWithRole('Productor', `Nueva Actividad Asignada: ${actividad.codigos}`, 'activityAssigned', context);
};

const notifyProducersNewActivity = async (newActivity) => {
  const context = {
    activityId: newActivity.id,
    eventType: 'nueva_actividad_disponible',
    activityCodigos: newActivity.codigos,
    activityAgencia: newActivity.agencia,
    activityCiudad: newActivity.ciudad,
    activityFecha: newActivity.fecha,
    activityLink: `${process.env.FRONTEND_URL || 'http://localhost:3000'}/actividades/${newActivity.id}`,
    appName: 'Tigo Administrativo'
  };

  // Notify ALL Producers and ALL Clients
  await notifyAllUsersWithRole('Productor', `Nueva Actividad Disponible: ${newActivity.codigos}`, 'newActivityNotification', context);
  await notifyAllUsersWithRole('Cliente', `Nueva Actividad Disponible: ${newActivity.codigos}`, 'newActivityNotification', context);
};

const notifyActivityCorrectionRequired = async (actividad, motivo) => {
  const context = {
    activityId: actividad.id,
    eventType: 'actividad_correccion',
    activityCodigos: actividad.codigos,
    motivo: motivo,
    activityLink: `${BASE_URL_API}/actividades/${actividad.id}`,
  };

  // Notify ALL Commercials
  await notifyAllUsersWithRole('Comercial', `Corrección Requerida para Actividad: ${actividad.codigos}`, 'activityCorrectionRequired', context);
};

const notifyEvidenceReadyForReview = async (actividad) => {
  const context = {
    activityId: actividad.id,
    eventType: 'evidencia_lista_revision',
    activityCodigos: actividad.codigos,
    activityLink: `${BASE_URL_API}/actividades/${actividad.id}`,
  };

  // Notify ALL Commercials
  await notifyAllUsersWithRole('Comercial', `Evidencias listas para revisión: ${actividad.codigos}`, 'evidenceReadyForReview', context);
};

module.exports = {
  createNotification,
  notifyActivityCreated,
  notifyActivityConfirmed,
  notifyEvidenceUploaded,
  notifyEvidenceRejected,
  notifyActivityFinalized,
  notifyActivityAssigned,
  notifyProducersNewActivity,
  notifyActivityCorrectionRequired,
  notifyEvidenceReadyForReview,
  addNotificationJob,
};
