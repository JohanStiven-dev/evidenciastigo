const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');

const Proyecto = sequelize.define('Proyecto', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true,
  },
  nombre: {
    type: DataTypes.STRING(255),
    allowNull: false,
  },
  cliente_id: {
    type: DataTypes.INTEGER,
    allowNull: true, // Assuming client_id can be null if not directly linked to a client user
  },
  fecha_inicio: {
    type: DataTypes.DATE,
    allowNull: true,
  },
  fecha_fin: {
    type: DataTypes.DATE,
    allowNull: true,
  },
  estado: {
    type: DataTypes.STRING(50),
    allowNull: true,
  },
}, {
  tableName: 'Proyectos',
  timestamps: true,
});

Proyecto.associate = (models) => {
  Proyecto.belongsTo(models.User, { as: 'Cliente', foreignKey: 'cliente_id' });
  Proyecto.hasMany(models.Actividad, { foreignKey: 'proyecto_id' });
};

module.exports = Proyecto;
