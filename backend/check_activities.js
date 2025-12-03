require('dotenv').config();
const { Actividad, User } = require('./src/models/init-associations');

async function checkActivities() {
    try {
        const activities = await Actividad.findAll({
            include: [
                { model: User, as: 'Comercial', attributes: ['id', 'nombre', 'rol'] }
            ]
        });

        console.log(`Total Activities: ${activities.length}`);
        activities.forEach(a => {
            console.log(`ID: ${a.id}, Code: ${a.codigos}, Status: ${a.status}, SubStatus: ${a.sub_status}, Comercial: ${a.Comercial?.nombre} (ID: ${a.comercial_id})`);
        });

    } catch (error) {
        console.error('Error:', error);
    } finally {
        process.exit();
    }
}

checkActivities();
