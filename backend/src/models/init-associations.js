// This file is responsible for loading all models and setting up their associations.
// By requiring this file, other parts of the application can get fully-associated models
// without causing circular dependency issues.

const Actividad = require('./ActividadModel');
const Bitacora = require('./BitacoraModel');
const Catalogo = require('./CatalogoModel');
const Evidencia = require('./EvidenciaModel');
const Notificacion = require('./NotificacionModel');
const PresupuestoItem = require('./PresupuestoItemModel');
const Presupuesto = require('./PresupuestoModel');
const Proyecto = require('./ProyectoModel');
const RefreshToken = require('./RefreshTokenModel');
const User = require('./UserModel');

const sequelize = require('../config/db');

const db = {
  sequelize, // Export the instance
  Actividad,
  Bitacora,
  Catalogo,
  Evidencia,
  Notificacion,
  PresupuestoItem,
  Presupuesto,
  Proyecto,
  RefreshToken,
  User,
};

// Call the associate method for each model, if it exists
Object.keys(db).forEach(modelName => {
  if (db[modelName].associate) {
    db[modelName].associate(db);
  }
});

module.exports = db;
