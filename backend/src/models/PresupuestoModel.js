const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');

const Presupuesto = sequelize.define('Presupuesto', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true,
  },
  actividad_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: 'Actividades',
      key: 'id',
    },
  },
  total_cop: {
    type: DataTypes.DECIMAL(10, 2),
    allowNull: false,
  },
  estado_presupuesto: {
    type: DataTypes.STRING(50),
    allowNull: true,
  },
  comentario_global: {
    type: DataTypes.TEXT,
    allowNull: true,
  },
  archivo_oc: {
    type: DataTypes.STRING,
    allowNull: true,
  },
}, {
  tableName: 'Presupuestos',
  timestamps: true,
});

Presupuesto.associate = (models) => {
  Presupuesto.belongsTo(models.Actividad, { foreignKey: 'actividad_id' });
  Presupuesto.hasMany(models.PresupuestoItem, { foreignKey: 'presupuesto_id' });
};

module.exports = Presupuesto;
