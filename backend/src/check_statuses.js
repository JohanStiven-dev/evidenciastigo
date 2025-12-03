require('dotenv').config();
const { Sequelize } = require('sequelize');
const sequelize = require('./config/db');
const Actividad = require('./models/ActividadModel');

async function checkStatuses() {
    try {
        await sequelize.authenticate();
        const activities = await Actividad.findAll({
            attributes: ['status', 'sub_status', [Sequelize.fn('COUNT', Sequelize.col('id')), 'count']],
            group: ['status', 'sub_status']
        });

        console.log('Activity Status Distribution:');
        activities.forEach(a => {
            console.log(`${a.status} - ${a.sub_status}: ${a.get('count')}`);
        });
        process.exit(0);
    } catch (error) {
        console.error(error);
        process.exit(1);
    }
}

checkStatuses();
