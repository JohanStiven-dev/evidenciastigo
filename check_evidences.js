require('dotenv').config();
const { Evidencia, PresupuestoItem, Presupuesto, Actividad } = require('./src/models/init-associations');

async function checkEvidences() {
    try {
        const actividadId = 4;
        const evidences = await Evidencia.findAll({
            include: {
                model: PresupuestoItem,
                required: true,
                include: {
                    model: Presupuesto,
                    required: true,
                    where: { actividad_id: actividadId }
                }
            }
        });

        console.log(`Found ${evidences.length} evidences for Activity ${actividadId}.`);
        evidences.forEach(e => {
            console.log(`ID: ${e.id}, Status: ${e.status}, Item: ${e.PresupuestoItem.item}`);
        });

        const allApproved = evidences.every(e => e.status === 'aprobado');
        console.log(`All Approved? ${allApproved}`);

    } catch (error) {
        console.error('Error:', error);
    } finally {
        process.exit();
    }
}

checkEvidences();
