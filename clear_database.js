require('dotenv').config();
const db = require('./src/models/init-associations');
const { sequelize } = db;

async function clearDatabase() {
    try {
        await sequelize.authenticate();
        console.log('Connection has been established successfully.');

        // Disable foreign key checks to allow truncation in any order
        await sequelize.query('SET FOREIGN_KEY_CHECKS = 0', { raw: true });

        const models = Object.values(db).filter(model => model.tableName);

        for (const model of models) {
            if (model.name === 'SequelizeMeta') continue; // Skip migration table
            console.log(`Truncating table: ${model.tableName}`);
            await model.destroy({ where: {}, truncate: true, force: true });
        }

        // Re-enable foreign key checks
        await sequelize.query('SET FOREIGN_KEY_CHECKS = 1', { raw: true });

        console.log('All tables cleared successfully.');
    } catch (error) {
        console.error('Unable to clear database:', error);
    } finally {
        await sequelize.close();
    }
}

clearDatabase();
