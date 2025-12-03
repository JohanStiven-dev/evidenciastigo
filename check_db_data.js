require('dotenv').config();
const { Sequelize } = require('sequelize');
const sequelize = require('./src/config/db');
const Actividad = require('./src/models/ActividadModel');

async function checkData() {
    try {
        await sequelize.authenticate();
        console.log('Connected.');

        const activities = await Actividad.findAll();
        console.log(`Total Activities: ${activities.length}`);

        const byMonth = {};
        activities.forEach(a => {
            const date = new Date(a.fecha);
            const key = `${date.getFullYear()}-${date.getMonth() + 1}`;
            byMonth[key] = (byMonth[key] || 0) + 1;
        });

        console.log('Activities by Month:', byMonth);
        process.exit(0);
    } catch (error) {
        console.error('Error:', error);
        process.exit(1);
    }
}

checkData();
