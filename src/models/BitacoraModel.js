const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');
const User = require('./UserModel');
const Actividad = require('./ActividadModel');

const Bitacora = sequelize.define('Bitacora', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true,
  },
  user_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: User,
      key: 'id',
    },
  },
  actividad_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: Actividad,
      key: 'id',
    },
  },
  accion: {
    type: DataTypes.STRING,
    allowNull: false,
    comment: 'Ej: Creación, Cambio de estado, Actualización de presupuesto',
  },
  desde_estado: {
    type: DataTypes.STRING,
    allowNull: true,
  },
  hacia_estado: {
    type: DataTypes.STRING,
    allowNull: true,
  },
  motivo: {
    type: DataTypes.TEXT,
    allowNull: true,
  },
  ip_address: {
    type: DataTypes.STRING,
    allowNull: true,
  },
}, {
  tableName: 'Bitacora',
  timestamps: true,
  updatedAt: false, // The audit log should be immutable
});

Bitacora.belongsTo(User, { foreignKey: 'user_id' });
Bitacora.belongsTo(Actividad, { foreignKey: 'actividad_id' });
Actividad.hasMany(Bitacora, { foreignKey: 'actividad_id' });

module.exports = Bitacora;