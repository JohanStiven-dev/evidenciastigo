require('dotenv').config();
const sequelize = require('./config/db');
const Actividad = require('./models/ActividadModel');

async function updateDates() {
    try {
        await sequelize.authenticate();
        console.log('Connection established.');

        const actividades = await Actividad.findAll();
        const now = new Date();

        console.log(`Found ${actividades.length} activities.`);

        for (let i = 0; i < actividades.length; i++) {
            const actividad = actividades[i];
            // Set date to tomorrow + i days to spread them out
            const newDate = new Date(now);
            newDate.setDate(now.getDate() + 1 + i);

            actividad.fecha = newDate;
            await actividad.save();
            console.log(`Updated Actividad ${actividad.codigos} to date: ${newDate.toISOString().split('T')[0]}`);
        }

        console.log('All dates updated.');
        process.exit(0);
    } catch (error) {
        console.error('Error updating dates:', error);
        process.exit(1);
    }
}

updateDates();
