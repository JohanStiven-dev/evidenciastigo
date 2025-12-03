require('dotenv').config();
const { Actividad, Proyecto, User } = require('./src/models/init-associations');

async function checkActivityProjectClient() {
    try {
        const actividadId = 4; // Assuming ID 4 from previous logs
        const actividad = await Actividad.findByPk(actividadId, {
            include: [{
                model: Proyecto,
                include: [{ model: User, as: 'Cliente' }]
            }]
        });

        if (!actividad) {
            console.log('Actividad not found');
            return;
        }

        console.log(`Actividad ID: ${actividad.id}`);
        console.log(`Proyecto ID: ${actividad.proyecto_id}`);

        if (actividad.Proyecto) {
            console.log(`Proyecto Name: ${actividad.Proyecto.nombre}`);
            if (actividad.Proyecto.Cliente) {
                console.log(`Cliente ID: ${actividad.Proyecto.Cliente.id}`);
                console.log(`Cliente Name: ${actividad.Proyecto.Cliente.nombre}`);
                console.log(`Cliente Role: ${actividad.Proyecto.Cliente.rol}`);
            } else {
                console.log('Proyecto has NO Cliente associated.');
            }
        } else {
            console.log('Actividad has NO Proyecto associated.');
        }

    } catch (error) {
        console.error('Error:', error);
    } finally {
        process.exit();
    }
}

checkActivityProjectClient();
