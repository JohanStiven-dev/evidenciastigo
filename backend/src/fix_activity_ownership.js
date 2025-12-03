require('dotenv').config();
const { Sequelize } = require('sequelize');
const sequelize = require('./config/db');
const Actividad = require('./models/ActividadModel');
const User = require('./models/UserModel');

async function fixOwnership() {
    try {
        await sequelize.authenticate();
        console.log('Connection established.');

        const comercialEmail = 'comercial@tigo.com.co';
        const productorEmail = 'productor@tigo.com.co';

        const comercial = await User.findOne({ where: { email: comercialEmail } });
        const productor = await User.findOne({ where: { email: productorEmail } });

        if (!comercial || !productor) {
            console.error('Users not found. Ensure comercial@tigo.com.co and productor@tigo.com.co exist.');
            process.exit(1);
        }

        console.log(`Found Comercial: ${comercial.email} (ID: ${comercial.id})`);
        console.log(`Found Productor: ${productor.email} (ID: ${productor.id})`);

        console.log('Updating all activities...');
        const [updatedCount] = await Actividad.update(
            {
                comercial_id: comercial.id,
                productor_id: productor.id
            },
            { where: {} } // Update ALL activities
        );

        console.log(`Successfully updated ${updatedCount} activities.`);
        process.exit(0);
    } catch (error) {
        console.error('Error:', error);
        process.exit(1);
    }
}

fixOwnership();
