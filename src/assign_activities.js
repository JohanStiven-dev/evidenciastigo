require('dotenv').config();
const sequelize = require('./config/db');
const User = require('./models/UserModel');
const Actividad = require('./models/ActividadModel');

async function assignActivities() {
    try {
        await sequelize.authenticate();
        console.log('Connection established.');

        // 1. Get the new users
        const productor = await User.findOne({ where: { email: 'productor@tigo.com.co' } });
        const comercial = await User.findOne({ where: { email: 'comercial@tigo.com.co' } });

        if (!productor || !comercial) {
            console.error('Users not found. Please run seed_users.js first.');
            process.exit(1);
        }

        console.log(`Assigning activities to Productor: ${productor.email} (ID: ${productor.id})`);
        console.log(`Assigning activities to Comercial: ${comercial.email} (ID: ${comercial.id})`);

        // 2. Get all activities
        const actividades = await Actividad.findAll();
        console.log(`Found ${actividades.length} activities.`);

        if (actividades.length === 0) {
            console.log('No activities to update.');
            process.exit(0);
        }

        // 3. Update them
        for (const actividad of actividades) {
            // Assign to the new users
            actividad.productor_id = productor.id;
            actividad.comercial_id = comercial.id; // Optional: take ownership
            await actividad.save();
            console.log(`Updated Actividad ${actividad.id} (${actividad.codigos})`);
        }

        console.log('All activities updated.');
        process.exit(0);
    } catch (error) {
        console.error('Error assigning activities:', error);
        process.exit(1);
    }
}

assignActivities();
