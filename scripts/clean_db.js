const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../.env') });
const sequelize = require('../src/config/db');
const { exec } = require('child_process');

async function cleanDatabase() {
    try {
        await sequelize.authenticate();
        console.log('Connection has been established successfully.');

        console.log('⚠️  STARTING DATABASE CLEANUP FOR PRODUCTION ⚠️');
        console.log('This will delete all transactional data.');

        // Disable foreign key checks
        await sequelize.query('SET FOREIGN_KEY_CHECKS = 0');

        const tablesToTruncate = [
            'Actividades',
            'Bitacoras',
            'Evidencias',
            'Notificaciones',
            'PresupuestoItems',
            'Presupuestos',
            'Proyectos',
            'RefreshTokens',
            // 'Users', // We will truncate users to ensure clean slate, then re-seed
            // 'Catalogos' // We will truncate catalogs to ensure clean slate, then re-seed
        ];

        // Truncate all tables including Users and Catalogos to start fresh
        const allTables = [
            ...tablesToTruncate,
            'Users',
            'Catalogos'
        ];

        for (const table of allTables) {
            console.log(`Truncating table: ${table}...`);
            try {
                await sequelize.query(`TRUNCATE TABLE ${table}`);
            } catch (err) {
                console.warn(`Could not truncate ${table} (might not exist), skipping...`);
            }
        }

        // Re-enable foreign key checks
        await sequelize.query('SET FOREIGN_KEY_CHECKS = 1');
        console.log('✅ Database cleaned.');

        // Run Seeders
        console.log('🌱 Seeding default Users...');
        await runScript('../src/seed_users.js');

        console.log('🌱 Seeding default Catalogs...');
        await runScript('../src/seed_catalogs.js');

        console.log('🎉 Production setup completed successfully!');
        process.exit(0);

    } catch (error) {
        console.error('❌ Error cleaning database:', error);
        process.exit(1);
    }
}

function runScript(scriptPath) {
    return new Promise((resolve, reject) => {
        const fullPath = path.join(__dirname, scriptPath);
        const backendDir = path.join(__dirname, '..');
        exec(`node ${fullPath}`, { cwd: backendDir }, (error, stdout, stderr) => {
            if (error) {
                console.error(`Error running ${scriptPath}:`, error);
                reject(error);
                return;
            }
            if (stdout) console.log(stdout);
            if (stderr) console.error(stderr);
            resolve();
        });
    });
}

cleanDatabase();
