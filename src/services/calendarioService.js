const { Actividad } = require('../models/init-associations');
const { Op } = require('sequelize');
const { STATUS, ROLES } = require('../utils/constants');
const icalGenerator = require('ical-generator');
const { BASE_URL_API } = require('../config/env');

const getCalendarEvents = async (startDate, endDate, userId, userRole) => {
  const where = {
    status: STATUS.CONFIRMADA,
    fecha: {
      [Op.between]: [startDate, endDate],
    },
  };

  // Apply RBAC for calendar view
  if (userRole === ROLES.COMERCIAL) {
    where.comercial_id = userId;
  } else if (userRole === ROLES.PRODUCTOR) {
    where.productor_id = userId;
  }
  // Admin and Cliente can see all (or client-specific for Cliente, which is not implemented yet)

  const actividades = await Actividad.findAll({
    where,
    attributes: ['id', 'punto_venta', 'direccion', 'fecha', 'hora_inicio', 'hora_fin', 'status'],
  });

  return actividades.map(act => ({
    id: act.id,
    title: `${act.punto_venta} - ${act.status}`,
    start: `${act.fecha}T${act.hora_inicio}`,
    end: `${act.fecha}T${act.hora_fin}`,
    allDay: false,
    extendedProps: {
      direccion: act.direccion,
      status: act.status,
    },
  }));
};

const generateIcsForActivity = async (actividadId) => {
  const actividad = await Actividad.findByPk(actividadId);

  if (!actividad) {
    return null;
  }

  const cal = icalGenerator.default({
    prodId: { company: 'AdministrativoTigo', product: 'Calendar' },
    name: `Actividad ${actividad.codigos}`,
  });

  const startDateTime = new Date(`${actividad.fecha}T${actividad.hora_inicio}`);
  const endDateTime = new Date(`${actividad.fecha}T${actividad.hora_fin}`);

  cal.createEvent({
    start: startDateTime,
    end: endDateTime,
    summary: `Actividad en ${actividad.punto_venta}`,
    description: `Detalles de la actividad:\nAgencia: ${actividad.agencia}\nDirección: ${actividad.direccion}\nEstado: ${actividad.status}`,
    location: actividad.direccion,
    url: `${BASE_URL_API}/actividades/${actividad.id}`, // Use BASE_URL_API
  });

  return cal.toString();
};

const generateIcsFeedForUser = async (userId, userRole) => {
  const cal = icalGenerator.default({
    prodId: { company: 'AdministrativoTigo', product: 'PersonalCalendar' },
    name: `Mi Calendario - ${userRole}`,
  });

  const where = {
    status: ACTIVIDAD_STATUS.PROGRAMADA,
  };

  if (userRole === ROLES.COMERCIAL) {
    where.comercial_id = userId;
  } else if (userRole === ROLES.PRODUCTOR) {
    where.productor_id = userId;
  } else {
    return null; // No access for other roles
  }

  const actividades = await Actividad.findAll({ where });

  actividades.forEach(actividad => {
    const startDateTime = new Date(`${actividad.fecha}T${actividad.hora_inicio}`);
    const endDateTime = new Date(`${actividad.fecha}T${actividad.hora_fin}`);

    cal.createEvent({
      start: startDateTime,
      end: endDateTime,
      summary: `Actividad en ${actividad.punto_venta} (${actividad.codigos})`,
      description: `Agencia: ${actividad.agencia}\nResponsable: ${actividad.responsable_actividad}\nDirección: ${actividad.direccion}\nEstado: ${actividad.status}`,
      location: actividad.direccion,
      url: `${BASE_URL_API}/actividades/${actividad.id}`,
      uid: `actividad-${actividad.id}@${BASE_URL_API.replace(/https?:\/\//, '')}`, // Unique ID for event
    });
  });

  return cal.toString();
};

module.exports = {
  getCalendarEvents,
  generateIcsForActivity,
  generateIcsFeedForUser,
};
