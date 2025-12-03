require('dotenv').config();
const app = require('./app');
const sequelize = require('./config/db');
const { startWorker } = require('./services/queue'); // Import the startWorker function

const PORT = process.env.PORT || 3000;

const startServer = async () => {
  try {
    await sequelize.authenticate();
    console.log('Connection to the database has been established successfully.');

    // Temporarily disable foreign key checks
    await sequelize.query('SET FOREIGN_KEY_CHECKS = 0');

    // Import models to ensure they are registered with Sequelize
    require('./models/UserModel');
    require('./models/ProyectoModel');
    require('./models/ActividadModel');
    require('./models/PresupuestoModel');
    require('./models/PresupuestoItemModel');
    require('./models/EvidenciaModel');
    require('./models/NotificacionModel');
    require('./models/BitacoraModel');
    require('./models/CatalogoModel');
    require('./models/RefreshTokenModel'); // Ensure RefreshTokenModel is also imported

    await sequelize.sync({ alter: false }); // Change back to force: false after initial setup
    console.log('All models were synchronized successfully.');

    // Re-enable foreign key checks
    await sequelize.query('SET FOREIGN_KEY_CHECKS = 1');

    // Start the notification worker
    startWorker();

    // Setup cron jobs
    const setupCronJobs = require('./config/cronJobs');
    setupCronJobs();

    app.listen(PORT, () => {
      console.log(`Server running on port ${PORT}`);
    });
  } catch (error) {
    console.error('Unable to connect to the database:', error);
    process.exit(1);
  }
};

startServer();
