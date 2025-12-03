require('dotenv').config();
const { User, Actividad, Presupuesto } = require('./src/models/init-associations');
const bcrypt = require('bcryptjs');

async function seedSharedData() {
    try {
        // 1. Create another Comercial user
        const salt = await bcrypt.genSalt(10);
        const hashedPassword = await bcrypt.hash('123456', salt);

        const [comercial2, created] = await User.findOrCreate({
            where: { email: 'comercial2@tigo.com.co' },
            defaults: {
                nombre: 'Otro Comercial',
                password: hashedPassword,
                rol: 'Comercial',
                empresa: 'Tigo',
                cargo: 'Vendedor',
            }
        });

        console.log(`Comercial 2 ${created ? 'created' : 'found'}: ${comercial2.id}`);

        // 1.5 Ensure Project exists
        const { Proyecto } = require('./src/models/init-associations');
        const [proyecto] = await Proyecto.findOrCreate({
            where: { nombre: 'Proyecto General' },
            defaults: {
                cliente_id: 1, // Assuming ID 1 is Cliente
                descripcion: 'Proyecto por defecto',
                fecha_inicio: new Date(),
                fecha_fin: new Date(new Date().setFullYear(new Date().getFullYear() + 1)),
                status: 'Activo'
            }
        });

        // 2. Create an activity for this new user
        const activity = await Actividad.create({
            comercial_id: comercial2.id,
            productor_id: 2, // Assuming ID 2 is Productor
            proyecto_id: proyecto.id,
            agencia: 'Agencia B',
            codigos: 'SHARED-001',
            semana: '48',
            responsable_actividad: 'Otro Comercial',
            segmento: 'Pymes',
            clase_ppto: 'Opex',
            canal: 'Directo',
            ciudad: 'Medellín',
            punto_venta: 'PDV Centro',
            direccion: 'Calle 10 # 20-30',
            fecha: new Date(),
            hora_inicio: '10:00',
            hora_fin: '12:00',
            status: 'Planificación',
            sub_status: 'Borrador',
            valor_total: 2000000,
            responsable_canal: 'Juan Perez',
            celular_responsable: '3001234567',
            recursos_agencia: 'Promotor',
        });

        console.log(`Activity created: ${activity.id} - ${activity.codigos}`);

        // 3. Create budget for it (since we added auto-creation logic, but manual create bypasses controller logic)
        await Presupuesto.create({
            actividad_id: activity.id,
            total_cop: activity.valor_total,
            estado_presupuesto: 'Pendiente',
            comentario_global: 'Presupuesto inicial auto-generado (seed).',
        });

        console.log('Budget created.');

    } catch (error) {
        console.error('Error:', error);
    } finally {
        process.exit();
    }
}

seedSharedData();
