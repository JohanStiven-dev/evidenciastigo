require('dotenv').config();
const { Evidencia, PresupuestoItem, Presupuesto, Actividad, Bitacora } = require('./src/models/init-associations');

async function forceFinalize() {
    try {
        const actividadId = 4;
        const actividad = await Actividad.findByPk(actividadId);

        if (!actividad) {
            console.log('Activity not found');
            return;
        }

        console.log(`Current Status: ${actividad.estado} - ${actividad.sub_estado}`);

        const allEvidences = await Evidencia.findAll({
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

        const allApproved = allEvidences.every(e => e.status === 'aprobado');
        console.log(`All Approved: ${allApproved}`);

        if (allApproved && allEvidences.length > 0) {
            console.log('Finalizing activity...');
            const oldActivityStatus = `${actividad.estado} - ${actividad.sub_estado}`;
            actividad.estado = 'Finalizada';
            actividad.sub_estado = 'Completado';
            await actividad.save();

            console.log('Activity saved.');

            // Log in Bitacora
            await Bitacora.create({
                actividad_id: actividad.id,
                user_id: 1, // System or Admin ID
                accion: 'Finalización Manual (Script)',
                motivo: 'Corrección de estado (todas las evidencias aprobadas)',
                desde_estado: oldActivityStatus,
                hacia_estado: 'Finalizada - Completado',
                ip_address: '127.0.0.1'
            });
            console.log('Bitacora entry created.');
        } else {
            console.log('Not all evidences are approved.');
        }

    } catch (error) {
        console.error('Error:', error);
    } finally {
        process.exit();
    }
}

forceFinalize();
