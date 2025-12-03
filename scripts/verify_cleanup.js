const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../.env') });
const sequelize = require('../src/config/db');
const Actividad = require('../src/models/ActividadModel');
const User = require('../src/models/UserModel');
const Catalogo = require('../src/models/CatalogoModel');

async function verify() {
    try {
        await sequelize.authenticate();

        const actividadCount = await Actividad.count();
        const userCount = await User.count();
        const catalogoCount = await Catalogo.count();

        console.log('Verification Results:');
        console.log(`Actividades: ${actividadCount} (Expected: 0)`);
        console.log(`Users: ${userCount} (Expected: 3)`);
        console.log(`Catalogos: ${catalogoCount} (Expected: > 0)`);

        if (actividadCount === 0 && userCount === 3 && catalogoCount > 0) {
            console.log('✅ Verification PASSED');
            process.exit(0);
        } else {
            console.error('❌ Verification FAILED');
            process.exit(1);
        }
    } catch (error) {
        console.error('Verification Error:', error);
        process.exit(1);
    }
}

verify();
