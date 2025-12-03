require('dotenv').config();
const { Actividad } = require('./src/models/init-associations');

async function assignProject() {
    try {
        const actividadId = 4;
        const proyectoId = 1;

        const [updated] = await Actividad.update({ proyecto_id: proyectoId }, {
            where: { id: actividadId }
        });

        if (updated) {
            console.log(`Successfully assigned Proyecto ${proyectoId} to Actividad ${actividadId}`);
        } else {
            console.log(`Failed to update Actividad ${actividadId}`);
        }
    } catch (error) {
        console.error('Error:', error);
    } finally {
        process.exit();
    }
}

assignProject();
