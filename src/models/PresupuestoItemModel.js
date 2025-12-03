const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');
const Presupuesto = require('./PresupuestoModel');

const PresupuestoItem = sequelize.define('PresupuestoItem', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true,
  },
  presupuesto_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: Presupuesto,
      key: 'id',
    },
  },
  item: {
    type: DataTypes.STRING(255),
    allowNull: false,
  },
  cantidad: {
    type: DataTypes.INTEGER,
    allowNull: false,
  },
  costo_unitario_cop: {
    type: DataTypes.DECIMAL(10, 2),
    allowNull: false,
  },
  subtotal_cop: {
    type: DataTypes.DECIMAL(10, 2),
    allowNull: false,
  },
  impuesto_cop: {
    type: DataTypes.DECIMAL(10, 2),
    allowNull: true,
  },
  comentario: {
    type: DataTypes.TEXT,
    allowNull: true,
  },
}, {
  tableName: 'PresupuestoItems',
  timestamps: true,
});

PresupuestoItem.associate = (models) => {
  PresupuestoItem.belongsTo(models.Presupuesto, { foreignKey: 'presupuesto_id' });
  PresupuestoItem.hasMany(models.Evidencia, { foreignKey: 'presupuesto_item_id' });
};

module.exports = PresupuestoItem;
