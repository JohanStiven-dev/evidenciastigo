const cron = require('node-cron');
const { addNotificationJob } = require('../services/queue');
const db = require('../models/init-associations');
const { Actividad, User, Notificacion, Proyecto } = db;
const { v4: uuidv4 } = require('uuid'); // Import uuidv4
const { Op } = require('sequelize');
const { ROLES } = require('../utils/constants');
const logger = require('./logger');
const moment = require('moment-timezone');
const { BASE_URL_API } = require('./env');

// Helper to get users for an activity
const getActivityUsers = async (actividad) => {
  const users = {};
  if (actividad.comercial_id) {
    users.comercial = await User.findByPk(actividad.comercial_id);
  }
  if (actividad.productor_id) {
    users.productor = await User.findByPk(actividad.productor_id);
  }

  // Fetch Cliente via Proyecto
  const actividadWithProject = await Actividad.findByPk(actividad.id, {
    include: [{ model: Proyecto, include: [{ model: User, as: 'Cliente' }] }]
  });

  if (actividadWithProject && actividadWithProject.Proyecto && actividadWithProject.Proyecto.Cliente) {
    users.cliente = actividadWithProject.Proyecto.Cliente;
  }

  return users;
};

const setupCronJobs = () => {
  // Schedule to run every 15 minutes
  cron.schedule('*/15 * * * *', async () => {
    const requestId = uuidv4(); // Generate a new requestId for the cron job execution
    logger.info('Running scheduled activity reminders job', { requestId });
    const now = moment();

    try {
      const activities = await Actividad.findAll({
        where: {
          status: {
            [Op.in]: ['Programada', 'En ejecución'],
          },
        },
        include: [
          { model: User, as: 'Comercial', attributes: ['id', 'nombre', 'email'] },
          { model: User, as: 'Productor', attributes: ['id', 'nombre', 'email'] },
        ],
      });

      for (const actividad of activities) {
        const activityStart = moment(`${actividad.fecha} ${actividad.hora_inicio}`);
        const activityEnd = moment(`${actividad.fecha} ${actividad.hora_fin}`);

        // --- T-24h Reminder ---
        const diff24h = activityStart.diff(now, 'hours');
        if (diff24h >= 23 && diff24h < 24) { // Trigger between 23 and 24 hours before
          logger.info(`Scheduling T-24h reminder for activity ${actividad.id}`, { requestId });
          const usersToNotify = await getActivityUsers(actividad);
          const context = {
            activityCodigos: actividad.codigos,
            activityAgencia: actividad.agencia,
            activityCiudad: actividad.ciudad,
            activityFecha: actividad.fecha,
            activityHoraInicio: actividad.hora_inicio,
            activityLink: `${BASE_URL_API}/actividades/${actividad.id}`,
            requestId: requestId, // Pass requestId to notification context
          };

          if (usersToNotify.comercial) {
            const notification = await Notificacion.create({
              user_id: usersToNotify.comercial.id,
              actividad_id: actividad.id,
              tipo_evento: 'recordatorio_24h',
              canal: 'email',
              payload: {
                subject: `Recordatorio T-24h: Actividad ${actividad.codigos}`,
                templateName: 'reminder24h',
                context: { ...context, userName: usersToNotify.comercial.nombre },
              },
              estado: 'pendiente',
            });
            await addNotificationJob('sendEmail', {
              userId: usersToNotify.comercial.id,
              to: usersToNotify.comercial.email,
              subject: notification.payload.subject,
              templateName: notification.payload.templateName,
              context: notification.payload.context,
              notificationId: notification.id,
              requestId: requestId,
            });
          }
          if (usersToNotify.productor) {
            const notification = await Notificacion.create({
              user_id: usersToNotify.productor.id,
              actividad_id: actividad.id,
              tipo_evento: 'recordatorio_24h',
              canal: 'email',
              payload: {
                subject: `Recordatorio T-24h: Actividad ${actividad.codigos}`,
                templateName: 'reminder24h',
                context: { ...context, userName: usersToNotify.productor.nombre },
              },
              estado: 'pendiente',
            });
            await addNotificationJob('sendEmail', {
              userId: usersToNotify.productor.id,
              to: usersToNotify.productor.email,
              subject: notification.payload.subject,
              templateName: notification.payload.templateName,
              context: notification.payload.context,
              notificationId: notification.id,
              requestId: requestId,
            });
          }
          if (usersToNotify.cliente) {
            const notification = await Notificacion.create({
              user_id: usersToNotify.cliente.id,
              actividad_id: actividad.id,
              tipo_evento: 'recordatorio_24h',
              canal: 'email',
              payload: {
                subject: `Recordatorio T-24h: Actividad ${actividad.codigos}`,
                templateName: 'reminder24h',
                context: { ...context, userName: usersToNotify.cliente.nombre },
              },
              estado: 'pendiente',
            });
            await addNotificationJob('sendEmail', {
              userId: usersToNotify.cliente.id,
              to: usersToNotify.cliente.email,
              subject: notification.payload.subject,
              templateName: notification.payload.templateName,
              context: notification.payload.context,
              notificationId: notification.id,
              requestId: requestId,
            });
          }
          // TODO: Mark reminder as sent in DB to prevent re-sending (e.g., set status in a separate model after job completion)
        }

        // --- T-2h Reminder ---
        const diff2h = activityStart.diff(now, 'hours');
        if (diff2h >= 1 && diff2h < 2) { // Trigger between 1 and 2 hours before
          logger.info(`Scheduling T-2h reminder for activity ${actividad.id}`, { requestId });
          const usersToNotify = await getActivityUsers(actividad);
          const context = {
            activityCodigos: actividad.codigos,
            activityAgencia: actividad.agencia,
            activityCiudad: actividad.ciudad,
            activityFecha: actividad.fecha,
            activityHoraInicio: actividad.hora_inicio,
            activityLink: `${BASE_URL_API}/actividades/${actividad.id}`,
            requestId: requestId,
          };

          if (usersToNotify.productor) {
            const notification = await Notificacion.create({
              user_id: usersToNotify.productor.id,
              actividad_id: actividad.id,
              tipo_evento: 'recordatorio_2h',
              canal: 'email',
              payload: {
                subject: `Recordatorio T-2h: Actividad ${actividad.codigos}`,
                templateName: 'reminder2h',
                context: { ...context, userName: usersToNotify.productor.nombre },
              },
              estado: 'pendiente',
            });
            await addNotificationJob('sendEmail', {
              userId: usersToNotify.productor.id,
              to: usersToNotify.productor.email,
              subject: notification.payload.subject,
              templateName: notification.payload.templateName,
              context: notification.payload.context,
              notificationId: notification.id,
              requestId: requestId,
            });
          }
          // TODO: Mark reminder as sent in DB
        }

        // --- T+1h (after hora_fin) Reminder for Evidences ---
        const diff1hAfterEnd = now.diff(activityEnd, 'hours');
        if (diff1hAfterEnd >= 0 && diff1hAfterEnd < 1) { // Trigger between 0 and 1 hour after end
          logger.info(`Scheduling T+1h evidence reminder for activity ${actividad.id}`, { requestId });
          const usersToNotify = await getActivityUsers(actividad);
          const context = {
            activityCodigos: actividad.codigos,
            activityAgencia: actividad.agencia,
            activityLink: `${BASE_URL_API}/actividades/${actividad.id}`,
            requestId: requestId,
          };

          if (usersToNotify.productor) {
            const notification = await Notificacion.create({
              user_id: usersToNotify.productor.id,
              actividad_id: actividad.id,
              tipo_evento: 'recordatorio_evidencia',
              canal: 'email',
              payload: {
                subject: `¡Sube tus Evidencias! Actividad ${actividad.codigos}`,
                templateName: 'reminder1hAfterEnd',
                context: { ...context, userName: usersToNotify.productor.nombre },
              },
              estado: 'pendiente',
            });
            await addNotificationJob('sendEmail', {
              userId: usersToNotify.productor.id,
              to: usersToNotify.productor.email,
              subject: notification.payload.subject,
              templateName: notification.payload.templateName,
              context: notification.payload.context,
              notificationId: notification.id,
              requestId: requestId,
            });
          }
          // TODO: Mark reminder as sent in DB
        }
      }
    } catch (error) {
      logger.error('Error in scheduled activity reminders job:', error, { requestId });
    }
  });
};

module.exports = setupCronJobs;
