const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');

const Actividad = sequelize.define('Actividad', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true,
  },
  proyecto_id: {
    type: DataTypes.INTEGER,
    allowNull: true,
    references: {
      model: 'Proyectos',
      key: 'id',
    },
  },
  comercial_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: 'Users',
      key: 'id',
    },
  },
  productor_id: {
    type: DataTypes.INTEGER,
    allowNull: true,
    references: {
      model: 'Users',
      key: 'id',
    },
  },
  agencia: {
    type: DataTypes.STRING(255),
    allowNull: false,
  },
  codigos: {
    type: DataTypes.STRING(255),
    allowNull: false,
  },
  semana: {
    type: DataTypes.STRING(10),
    allowNull: false,
  },
  responsable_actividad: {
    type: DataTypes.STRING(255),
    allowNull: false,
  },
  segmento: {
    type: DataTypes.STRING(255),
    allowNull: false,
  },
  clase_ppto: {
    type: DataTypes.STRING(255),
    allowNull: false,
  },
  canal: {
    type: DataTypes.STRING(255),
    allowNull: false,
  },
  ciudad: {
    type: DataTypes.STRING(255),
    allowNull: false,
  },
  punto_venta: {
    type: DataTypes.STRING(255),
    allowNull: false,
  },
  direccion: {
    type: DataTypes.STRING(255),
    allowNull: false,
  },
  fecha: {
    type: DataTypes.DATEONLY,
    allowNull: false,
  },
  hora_inicio: {
    type: DataTypes.TIME,
    allowNull: false,
  },
  hora_fin: {
    type: DataTypes.TIME,
    allowNull: false,
  },
  status: {
    type: DataTypes.ENUM(
      'Planificación',
      'Confirmada',
      'En Curso',
      'Finalizada'
    ),
    allowNull: false,
    defaultValue: 'Planificación',
  },
  sub_status: {
    type: DataTypes.ENUM(
      'Borrador',
      'En Revisión',
      'Rechazado',
      'Aprobación Final',
      'Programada',
      'En Ejecución',
      'Cargando Evidencias',
      'Completado',
      'Cancelado'
    ),
    allowNull: true,
    defaultValue: 'Borrador',
  },
  valor_total: {
    type: DataTypes.DECIMAL(12, 2),
    allowNull: false,
    defaultValue: 0.00,
  },
  responsable_canal: {
    type: DataTypes.STRING(255),
    allowNull: true,
  },
  celular_responsable: {
    type: DataTypes.STRING(50),
    allowNull: true,
  },
  recursos_agencia: {
    type: DataTypes.TEXT,
    allowNull: true,
  },
}, {
  tableName: 'Actividades',
  timestamps: true,
  hooks: {
    beforeValidate: (actividad, options) => {
      if (actividad.fecha) {
        const date = new Date(actividad.fecha);
        // Adjust to make Monday the first day of the week
        const day = date.getUTCDay() || 7;
        date.setUTCDate(date.getUTCDate() + 4 - day);
        const yearStart = new Date(Date.UTC(date.getUTCFullYear(), 0, 1));
        const weekNo = Math.ceil((((date - yearStart) / 86400000) + 1) / 7);
        actividad.semana = weekNo.toString();
      }
    },
  },
});

Actividad.associate = (models) => {
  Actividad.belongsTo(models.User, { as: 'Comercial', foreignKey: 'comercial_id' });
  Actividad.belongsTo(models.User, { as: 'Productor', foreignKey: 'productor_id' });
  Actividad.belongsTo(models.Proyecto, { foreignKey: 'proyecto_id' });
  Actividad.hasOne(models.Presupuesto, {
    foreignKey: 'actividad_id',
    as: 'Presupuesto',
  });

};

module.exports = Actividad;
