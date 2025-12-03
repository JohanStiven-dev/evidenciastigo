'use strict';

module.exports = {
  async up (queryInterface, Sequelize) {
    await queryInterface.addColumn('Actividades', 'valor_total', {
      type: Sequelize.DECIMAL(12, 2),
      allowNull: false,
      defaultValue: 0.00,
    });
  },

  async down (queryInterface, Sequelize) {
    await queryInterface.removeColumn('Actividades', 'valor_total');
  }
};