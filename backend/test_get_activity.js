require('dotenv').config();
const { Actividad, User, Presupuesto, PresupuestoItem, Evidencia } = require('./src/models/init-associations');

async function getActivity() {
    try {
        const id = 4; // Activity 4 is Finalized
        console.log(`Fetching Activity ${id}...`);

        const actividad = await Actividad.findByPk(id, {
            include: [
                { model: User, as: 'Comercial', attributes: ['id', 'nombre', 'email'] },
                { model: User, as: 'Productor', attributes: ['id', 'nombre', 'email'] },
                { model: Presupuesto, as: 'Presupuesto', include: [PresupuestoItem] },
                { model: Evidencia, as: 'evidencias' }
            ],
        });

        if (!actividad) {
            console.log('Activity not found');
        } else {
            console.log('Activity found:', actividad.id);
            console.log('Status:', actividad.estado);
        }

    } catch (error) {
        console.error('Error fetching activity:', error);
    } finally {
        process.exit();
    }
}

getActivity();
