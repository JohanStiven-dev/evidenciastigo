'use strict';

module.exports = {
  up: async (queryInterface, Sequelize) => {
    // First, add the new column with allowNull: true to handle existing rows
    await queryInterface.addColumn('Evidencias', 'presupuesto_item_id', {
      type: Sequelize.INTEGER,
      allowNull: true,
      references: {
        model: 'PresupuestoItems', // name of the target table
        key: 'id',
      },
      onUpdate: 'CASCADE',
      onDelete: 'SET NULL',
    });

    // Note: In a real-world scenario, you would write a data migration script here
    // to populate 'presupuesto_item_id' for existing evidences before making the column non-nullable
    // and removing 'actividad_id'. For this case, we will assume we can drop the old column.
    
    // Then, remove the old column
    await queryInterface.removeColumn('Evidencias', 'actividad_id');
    
    // Finally, alter the new column to be NOT NULL, if required by the new model.
    // We will leave it as nullable to avoid issues with old data that can't be migrated.
  },

  down: async (queryInterface, Sequelize) => {
    // To reverse, first add the old 'actividad_id' column back
    await queryInterface.addColumn('Evidencias', 'actividad_id', {
      type: Sequelize.INTEGER,
      allowNull: true, // Assuming it could be null
      references: {
        model: 'Actividades',
        key: 'id',
      },
      onUpdate: 'CASCADE',
      onDelete: 'SET NULL',
    });

    // Then remove the 'presupuesto_item_id' column
    await queryInterface.removeColumn('Evidencias', 'presupuesto_item_id');
  }
};
