require('dotenv').config();
const { Actividad } = require('./src/models/init-associations');
const { Op } = require('sequelize');

async function findActivity() {
    try {
        const activities = await Actividad.findAll({
            where: {
                codigos: { [Op.like]: '%Prueba002%' }
            }
        });

        console.log(`Found ${activities.length} activities.`);
        activities.forEach(a => {
            console.log(`ID: ${a.id}, Codigos: ${a.codigos}, Estado: ${a.estado}, SubEstado: ${a.sub_estado}`);
        });
    } catch (error) {
        console.error('Error:', error);
    } finally {
        process.exit();
    }
}

findActivity();
