'use strict';

// Final migration for updating activity statuses.

module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.sequelize.transaction(async (transaction) => {
      // 1. Add sub_status and a temporary new_status column
      await queryInterface.addColumn('Actividades', 'sub_status', {
        type: Sequelize.STRING,
        allowNull: true,
      }, { transaction });

      await queryInterface.addColumn('Actividades', 'new_status', {
        type: Sequelize.STRING,
        allowNull: true,
      }, { transaction });

      // 2. Map old statuses to new ones
      const mapping = {
        'Borrador': { status: 'Planificación', sub_status: 'Borrador' },
        'Registrada': { status: 'Planificación', sub_status: 'En Revisión' },
        'En validación': { status: 'Planificación', sub_status: 'En Revisión' },
        'Aprobación cliente': { status: 'Planificación', sub_status: 'En Revisión' },
        'Devuelta': { status: 'Planificación', sub_status: 'Rechazado' },
        'Programada': { status: 'Confirmada', sub_status: 'Programada' },
        'En ejecución': { status: 'En Curso', sub_status: 'En Ejecución' },
        'Evidencias cargadas': { status: 'En Curso', sub_status: 'Cargando Evidencias' },
        'Cerrada': { status: 'Finalizada', sub_status: 'Completado' },
        'Rechazada': { status: 'Finalizada', sub_status: 'Cancelado' },
      };

      for (const oldStatus of Object.keys(mapping)) {
        const { status: newStatus, sub_status: newSubStatus } = mapping[oldStatus];
        await queryInterface.bulkUpdate('Actividades', 
          { new_status: newStatus, sub_status: newSubStatus },
          { status: oldStatus },
          { transaction }
        );
      }

      // 3. Drop the old status column
      await queryInterface.removeColumn('Actividades', 'status', { transaction });
      
      // 4. Re-add the status column with the new ENUM type
      await queryInterface.addColumn('Actividades', 'status', {
        type: Sequelize.ENUM('Planificación', 'Confirmada', 'En Curso', 'Finalizada'),
        allowNull: false,
        defaultValue: 'Planificación',
      }, { transaction });

      // 5. Copy data from the temp column to the new one
      await queryInterface.sequelize.query(
        'UPDATE Actividades SET status = new_status',
        { transaction }
      );

      // 6. Change sub_status column to the proper ENUM type
      await queryInterface.changeColumn('Actividades', 'sub_status', {
        type: Sequelize.ENUM('Borrador', 'En Revisión', 'Rechazado', 'Programada', 'En Ejecución', 'Cargando Evidencias', 'Completado', 'Cancelado'),
        allowNull: true,
      }, { transaction });
      
      // 7. Drop the temp column
      await queryInterface.removeColumn('Actividades', 'new_status', { transaction });
    });
  },

  async down(queryInterface, Sequelize) {
    await queryInterface.sequelize.transaction(async (transaction) => {
      await queryInterface.removeColumn('Actividades', 'sub_status', { transaction });
      await queryInterface.changeColumn('Actividades', 'status', {
        type: Sequelize.ENUM(
          'Borrador', 'Registrada', 'En validación', 'Aprobación cliente', 
          'Programada', 'En ejecución', 'Evidencias cargadas', 'Cerrada', 
          'Rechazada', 'Devuelta'
        ),
        allowNull: false,
        defaultValue: 'Borrador',
      }, { transaction });
    });
  }
};