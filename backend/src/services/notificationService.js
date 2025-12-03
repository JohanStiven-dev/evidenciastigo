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
        await addNotificationJob('sendEmail', {
          userId: user.id,
          to: user.email,
          subject: payload.subject,
          templateName: payload.templateName,
          context: payload.context,
          notificationId: notification.id,
        });
      }
    }

    return notification;
  } catch (error) {
    console.error('Error creating or sending notification:', error);
  }
};

const notifyActivityCreated = async (actividad, cliente) => {
  if (!cliente || !cliente.email) return;

  const context = {
    userName: cliente.nombre,
    activityCodigos: actividad.codigos,
    activityAgencia: actividad.agencia,
    activityCiudad: actividad.ciudad,
    activityFecha: actividad.fecha,
    activityLink: `${BASE_URL_API}/actividades/${actividad.id}`,
  };

  await createNotification(cliente.id, actividad.id, 'actividad_creada', 'email', {
    subject: `Nueva Actividad Creada: ${actividad.codigos}`,
    templateName: 'activityCreated',
    context,
  });
};

const notifyActivityConfirmed = async (actividad, comercial, productor) => {
  const contextBase = {
    activityCodigos: actividad.codigos,
    activityAgencia: actividad.agencia,
    activityCiudad: actividad.ciudad,
    activityFecha: actividad.fecha,
    activityLink: `${BASE_URL_API}/actividades/${actividad.id}`,
  };

  if (comercial && comercial.email) {
    await createNotification(comercial.id, actividad.id, 'actividad_confirmada', 'email', {
      subject: `Actividad Aprobada: ${actividad.codigos}`,
      templateName: 'activityConfirmed',
      context: { ...contextBase, userName: comercial.nombre },
    });
  }

  if (productor && productor.email) {
    await createNotification(productor.id, actividad.id, 'actividad_confirmada', 'email', {
      subject: `Actividad Aprobada: ${actividad.codigos}`,
      templateName: 'activityConfirmed',
      context: { ...contextBase, userName: productor.nombre },
    });
  }
};

const notifyEvidenceUploaded = async (actividad, cliente, item, tipo) => {
  if (!cliente || !cliente.email) return;

  const context = {
    userName: cliente.nombre,
    activityCodigos: actividad.codigos,
    itemName: item.item,
    evidenceType: tipo,
    activityLink: `${BASE_URL_API}/actividades/${actividad.id}`,
  };

  await createNotification(cliente.id, actividad.id, 'evidencia_subida', 'email', {
    subject: `Nueva Evidencia Cargada: ${actividad.codigos}`,
    templateName: 'evidenceUploaded',
    context,
  });
};

const notifyEvidenceRejected = async (actividad, evidencia, motivo, productor) => {
  if (!productor || !productor.email) return;

  // Fetch item name if not available
  let itemName = 'Item desconocido';
  if (evidencia.PresupuestoItem) {
    itemName = evidencia.PresupuestoItem.item;
  }

  const context = {
    userName: productor.nombre,
    activityCodigos: actividad.codigos,
    itemName: itemName,
    rejectionReason: motivo,
    activityLink: `${BASE_URL_API}/actividades/${actividad.id}`,
  };

  await createNotification(productor.id, actividad.id, 'evidencia_rechazada', 'email', {
    subject: `Evidencia Rechazada: ${actividad.codigos}`,
    templateName: 'evidenceRejected',
    context,
  });
};

const notifyActivityFinalized = async (actividad, comercial, productor, cliente) => {
  const contextBase = {
    activityCodigos: actividad.codigos,
    activityAgencia: actividad.agencia,
    activityCiudad: actividad.ciudad,
    activityFecha: actividad.fecha,
    activityLink: `${BASE_URL_API}/actividades/${actividad.id}`,
  };

  const usersToNotify = [comercial, productor, cliente].filter(u => u && u.email);

  for (const user of usersToNotify) {
    await createNotification(user.id, actividad.id, 'actividad_finalizada', 'email', {
      subject: `Actividad Finalizada: ${actividad.codigos}`,
      templateName: 'activityFinalized',
      context: { ...contextBase, userName: user.nombre },
    });
  }
};


module.exports = {
  createNotification,
  notifyActivityCreated,
  notifyActivityConfirmed,
  notifyEvidenceUploaded,
  notifyEvidenceRejected,
  notifyActivityFinalized,
};
