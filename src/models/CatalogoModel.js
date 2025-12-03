const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');

const Catalogo = sequelize.define('Catalogo', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true,
  },
  tipo: {
    type: DataTypes.ENUM('ciudad', 'canal', 'segmento', 'clase_ppto'),
    allowNull: false,
  },
  valor: {
    type: DataTypes.STRING(255),
    allowNull: false,
    unique: true,
  },
  activo: {
    type: DataTypes.BOOLEAN,
    allowNull: false,
    defaultValue: true,
  },
}, {
  tableName: 'Catalogos',
  timestamps: true,
});

module.exports = Catalogo;
