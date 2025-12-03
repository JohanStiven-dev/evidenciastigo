'use strict';

const subStatuses = ['Borrador', 'En Revisión', 'Rechazado', 'Programada', 'En Ejecución', 'Cargando Evidencias', 'Completado', 'Cancelado'];
const newSubStatuses = [...subStatuses, 'Aprobación Final'];

module.exports = {
  async up (queryInterface, Sequelize) {
    await queryInterface.changeColumn('Actividades', 'sub_status', {
      type: Sequelize.ENUM(...newSubStatuses),
      allowNull: true,
      defaultValue: 'Borrador',
    });
  },

  async down (queryInterface, Sequelize) {
    // This will remove 'Aprobación Final' and may cause data loss if that value is in use.
    await queryInterface.changeColumn('Actividades', 'sub_status', {
      type: Sequelize.ENUM(...subStatuses),
      allowNull: true,
      defaultValue: 'Borrador',
    });
  }
};