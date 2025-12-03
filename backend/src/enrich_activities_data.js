require('dotenv').config();
const { Sequelize } = require('sequelize');
const sequelize = require('./config/db');
const {
    Actividad,
    Presupuesto,
    PresupuestoItem,
    Evidencia
} = require('./models/init-associations');

async function enrichData() {
    const t = await sequelize.transaction();
    try {
        await sequelize.authenticate();
        console.log('Connection established.');

        const actividades = await Actividad.findAll({ transaction: t });
        console.log(`Found ${actividades.length} activities.`);

        let updatedCount = 0;
        let evidenceCount = 0;

        for (const actividad of actividades) {
            // 1. Create Presupuesto if not exists
            let [presupuesto, created] = await Presupuesto.findOrCreate({
                where: { actividad_id: actividad.id },
                defaults: {
                    total_cop: 0, // Will update later
                    estado_presupuesto: 'Aprobado',
                    comentario_global: 'Presupuesto asignado automáticamente.'
                },
                transaction: t
            });

            // 2. Create Items if not exist
            const existingItems = await PresupuestoItem.count({ where: { presupuesto_id: presupuesto.id }, transaction: t });

            let totalPresupuesto = 0;
            let items = [];

            if (existingItems === 0) {
                const itemsToCreate = [
                    { item: 'Personal Logístico', cantidad: 2, costo: 150000 },
                    { item: 'Transporte', cantidad: 1, costo: 50000 },
                    { item: 'Refrigerios', cantidad: 5, costo: 10000 }
                ];

                for (const itemData of itemsToCreate) {
                    const subtotal = itemData.cantidad * itemData.costo;
                    const newItem = await PresupuestoItem.create({
                        presupuesto_id: presupuesto.id,
                        item: itemData.item,
                        cantidad: itemData.cantidad,
                        costo_unitario_cop: itemData.costo,
                        subtotal_cop: subtotal,
                        impuesto_cop: 0,
                        comentario: 'Item generado automáticamente'
                    }, { transaction: t });

                    items.push(newItem);
                    totalPresupuesto += subtotal;
                }

                // Update Presupuesto total
                presupuesto.total_cop = totalPresupuesto;
                await presupuesto.save({ transaction: t });
                updatedCount++;
            } else {
                // If items exist, just get them for evidence linking
                items = await PresupuestoItem.findAll({ where: { presupuesto_id: presupuesto.id }, transaction: t });
            }

            // 3. Add Evidence if Finalizada
            if (actividad.status === 'Finalizada') {
                // Force sub_status to Completado if it's Finalizada
                if (actividad.sub_status !== 'Completado') {
                    actividad.sub_status = 'Completado';
                    await actividad.save({ transaction: t });
                }

                // Check if evidence already exists
                const existingEvidence = await Evidencia.count({
                    include: [{ model: PresupuestoItem, where: { presupuesto_id: presupuesto.id } }],
                    transaction: t
                });

                if (existingEvidence === 0 && items.length > 0) {
                    // Attach to the first item
                    await Evidencia.create({
                        presupuesto_item_id: items[0].id,
                        tipo: 'foto_actividad',
                        archivo_path: 'evidencia_placeholder.png', // Relative to uploads dir
                        archivo_nombre: 'evidencia_final.png',
                        status: 'aprobado',
                        comentario: 'Evidencia de cierre exitoso (Auto-generada)'
                    }, { transaction: t });
                    evidenceCount++;
                }
            }
        }

        await t.commit();
        console.log(`Enrichment complete.`);
        console.log(`- Activities with new budgets: ${updatedCount}`);
        console.log(`- New evidence records created: ${evidenceCount}`);
        process.exit(0);

    } catch (error) {
        await t.rollback();
        console.error('Error enriching data:', error);
        process.exit(1);
    }
}

enrichData();
