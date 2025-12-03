require('dotenv').config();
const { Sequelize } = require('sequelize');
const sequelize = require('./config/db');
const {
    Actividad,
    Presupuesto,
    PresupuestoItem,
    Evidencia
} = require('./models/init-associations');

async function debugEvidence() {
    try {
        await sequelize.authenticate();
        console.log('Connection established.');

        const pItemId = 38; // One of the IDs causing error

        console.log(`Fetching PresupuestoItem ${pItemId}...`);

        // Mimic the controller query
        const pItem = await PresupuestoItem.findByPk(pItemId, {
            include: [{
                model: Presupuesto,
                include: [{
                    model: Actividad,
                    attributes: ['id', 'comercial_id', 'productor_id']
                }]
            }]
        });

        if (!pItem) {
            console.log('PresupuestoItem not found (would return 404)');
        } else {
            console.log('PresupuestoItem found:', pItem.id);
            console.log('Presupuesto:', pItem.Presupuesto ? pItem.Presupuesto.id : 'null');
            console.log('Actividad:', pItem.Presupuesto && pItem.Presupuesto.Actividad ? pItem.Presupuesto.Actividad.id : 'null');
        }

        process.exit(0);
    } catch (error) {
        console.error('Error reproduced:', error);
        process.exit(1);
    }
}

debugEvidence();
