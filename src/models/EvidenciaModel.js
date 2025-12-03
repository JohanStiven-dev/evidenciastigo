const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');

const Evidencia = sequelize.define('Evidencia', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true,
  },
  presupuesto_item_id: { // New foreign key
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: 'PresupuestoItems', // Reference the actual table name
      key: 'id',
    },
  },
  tipo: {
    type: DataTypes.ENUM('foto_recibo', 'foto_actividad', 'otro'),
    allowNull: false,
  },
  archivo_path: {
    type: DataTypes.STRING(255),
    allowNull: false,
  },
  archivo_nombre: {
    type: DataTypes.STRING(255),
    allowNull: false,
  },
  mime: {
    type: DataTypes.STRING(100),
    allowNull: true,
  },
  peso_bytes: {
    type: DataTypes.INTEGER,
    allowNull: true,
  },
  comentario: {
    type: DataTypes.TEXT,
    allowNull: true,
  },
  status: {
    type: DataTypes.ENUM('pendiente', 'aprobado', 'rechazado'),
    defaultValue: 'pendiente',
    allowNull: false,
  },
}, {
  tableName: 'Evidencias',
  timestamps: true,
});

Evidencia.associate = (models) => {
  Evidencia.belongsTo(models.PresupuestoItem, { foreignKey: 'presupuesto_item_id' });
};

module.exports = Evidencia;
