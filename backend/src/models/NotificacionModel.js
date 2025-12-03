const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');

const Notificacion = sequelize.define('Notificacion', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true,
  },
  user_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: 'Users',
      key: 'id',
    },
  },
  actividad_id: {
    type: DataTypes.INTEGER,
    allowNull: true,
    references: {
      model: 'Actividades',
      key: 'id',
    },
  },
  tipo_evento: {
    type: DataTypes.STRING(255),
    allowNull: false,
  },
  canal: {
    type: DataTypes.ENUM('email', 'app', 'sms'),
    allowNull: false,
  },
  payload: {
    type: DataTypes.JSON,
    allowNull: true,
  },
  enviado_at: {
    type: DataTypes.DATE,
    allowNull: true,
  },
  estado: {
    type: DataTypes.ENUM('pendiente', 'enviado', 'fallido', 'leida'),
    allowNull: false,
    defaultValue: 'pendiente',
  },
  error_msg: {
    type: DataTypes.TEXT,
    allowNull: true,
  },
  retry_count: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 0,
  },
}, {
  tableName: 'Notificaciones',
  timestamps: true,
});

Notificacion.associate = (models) => {
  Notificacion.belongsTo(models.User, { foreignKey: 'user_id' });
  Notificacion.belongsTo(models.Actividad, { foreignKey: 'actividad_id' });
};

module.exports = Notificacion;
