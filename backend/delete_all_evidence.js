require('dotenv').config({ path: './backend/.env' });
const sequelize = require('./src/config/db');
const Evidencia = require('./src/models/EvidenciaModel');

const deleteAllEvidence = async () => {
  try {
    await sequelize.authenticate();
    console.log('Database connection has been established successfully.');

    console.log('Deleting all existing evidence records...');
    const deletedCount = await Evidencia.destroy({ where: {}, truncate: true }); // truncate to reset IDs if needed
    console.log(`Deleted ${deletedCount} evidence records.`);

    console.log('\n✅ All evidence records deleted successfully!');

  } catch (error) {
    console.error('❌ Error deleting evidence records:', error);
  } finally {
    await sequelize.close();
    console.log('Database connection closed.');
  }
};

deleteAllEvidence();
