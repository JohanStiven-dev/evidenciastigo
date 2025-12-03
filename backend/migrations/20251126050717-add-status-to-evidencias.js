'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.addColumn('Evidencias', 'status', {
      type: Sequelize.ENUM('pendiente', 'aprobado', 'rechazado'),
      allowNull: false,
      defaultValue: 'pendiente',
    });
  },

  async down(queryInterface, Sequelize) {
    // To remove the ENUM type, we need to first remove the column
    // and then remove the type in PostgreSQL. For other DBs, this is enough.
    await queryInterface.removeColumn('Evidencias', 'status');
    // If using PostgreSQL, you might need to drop the enum type separately:
    // await queryInterface.sequelize.query('DROP TYPE "enum_Evidencias_status";');
  }
};
