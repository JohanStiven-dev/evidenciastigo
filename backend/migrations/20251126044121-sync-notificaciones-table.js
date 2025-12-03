'use strict';

module.exports = {
  async up (queryInterface, Sequelize) {
    await queryInterface.addColumn('Notificaciones', 'error_msg', {
      type: Sequelize.TEXT,
      allowNull: true,
    });
    await queryInterface.addColumn('Notificaciones', 'retry_count', {
      type: Sequelize.INTEGER,
      allowNull: false,
      defaultValue: 0,
    });
    // Also add 'leida' to the estado ENUM, as it's used in the logic
    await queryInterface.changeColumn('Notificaciones', 'estado', {
      type: Sequelize.ENUM('pendiente', 'enviado', 'fallido', 'leida'),
      allowNull: false,
      defaultValue: 'pendiente',
    });
  },

  async down (queryInterface, Sequelize) {
    await queryInterface.removeColumn('Notificaciones', 'error_msg');
    await queryInterface.removeColumn('Notificaciones', 'retry_count');
    await queryInterface.changeColumn('Notificaciones', 'estado', {
      type: Sequelize.ENUM('pendiente', 'enviado', 'fallido'),
      allowNull: false,
      defaultValue: 'pendiente',
    });
  }
};