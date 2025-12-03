require('dotenv').config();
const { Sequelize } = require('sequelize');
const sequelize = require('./config/db');
const Actividad = require('./models/ActividadModel');
const User = require('./models/UserModel');
const Presupuesto = require('./models/PresupuestoModel');
const PresupuestoItem = require('./models/PresupuestoItemModel');
const Evidencia = require('./models/EvidenciaModel');
const Bitacora = require('./models/BitacoraModel');

const ROLES = {
    ADMIN: 'Admin',
    COMERCIAL: 'Comercial',
    PRODUCTOR: 'Productor',
    CLIENTE: 'Cliente',
};

const STATUS_FLOW = [
    { status: 'Planificación', subStatus: 'Borrador' },
    { status: 'Planificación', subStatus: 'En Revisión' },
    { status: 'Planificación', subStatus: 'Rechazado' },
    { status: 'Confirmada', subStatus: 'Programada' },
    { status: 'En Curso', subStatus: 'En Ejecución' },
    { status: 'En Curso', subStatus: 'Cargando Evidencias' },
    { status: 'En Curso', subStatus: 'Aprobación Final' },
    { status: 'Finalizada', subStatus: 'Completado' },
    { status: 'Finalizada', subStatus: 'Cancelado' },
];

const CIUDADES = ['Bogotá', 'Medellín', 'Cali', 'Barranquilla', 'Cartagena', 'Bucaramanga'];
const CANALES = ['Tiendas', 'Kioscos', 'Mayoristas', 'TAT', 'Grandes Superficies'];

async function seed() {
    try {
        await sequelize.authenticate();
        console.log('Connection has been established successfully.');

        // 1. Clear existing transactional data
        console.log('Clearing existing data...');
        await Bitacora.destroy({ where: {}, truncate: false }); // Truncate might fail with FKs
        await Evidencia.destroy({ where: {}, truncate: false });
        await PresupuestoItem.destroy({ where: {}, truncate: false });
        await Presupuesto.destroy({ where: {}, truncate: false });
        await Actividad.destroy({ where: {}, truncate: false });

        console.log('Data cleared.');

        // 2. Get Users
        const comercial = await User.findOne({ where: { rol: ROLES.COMERCIAL } });
        const productor = await User.findOne({ where: { rol: ROLES.PRODUCTOR } });

        if (!comercial || !productor) {
            console.error('Error: Ensure Comercial and Productor users exist first.');
            return;
        }

        const activitiesToCreate = [];
        const year = 2025;

        // 3. Generate Data
        for (let month = 0; month < 12; month++) {
            for (let i = 0; i < 10; i++) {
                const state = STATUS_FLOW[Math.floor(Math.random() * STATUS_FLOW.length)];
                const ciudad = CIUDADES[Math.floor(Math.random() * CIUDADES.length)];
                const canal = CANALES[Math.floor(Math.random() * CANALES.length)];

                // Random day in month
                const day = Math.floor(Math.random() * 28) + 1;
                const date = new Date(year, month, day);

                // Calculate week number (simple approximation)
                const oneJan = new Date(year, 0, 1);
                const numberOfDays = Math.floor((date - oneJan) / (24 * 60 * 60 * 1000));
                const semana = Math.ceil((date.getDay() + 1 + numberOfDays) / 7);

                activitiesToCreate.push({
                    fecha: date,
                    semana: `S${semana}`,
                    mes: date.toLocaleString('es-CO', { month: 'long' }),
                    anio: year,
                    codigos: `ACT-${year}-${month + 1}-${i + 1}`,
                    agencia: 'Agencia Tigo Test',
                    ciudad: ciudad,
                    regional: 'Nacional',
                    puntoVenta: `PDV ${ciudad} ${i + 1}`,
                    direccion: `Calle ${Math.floor(Math.random() * 100)} # ${Math.floor(Math.random() * 100)} - ${Math.floor(Math.random() * 100)}`,
                    canal: canal,
                    responsableCanal: 'Juan Perez',
                    celularResponsable: '3001234567',
                    segmento: 'Masivo',
                    clasePpto: 'Opex',
                    recursosAgencia: 'Promotor, Material POP',
                    horaInicio: '08:00',
                    horaFin: '17:00',
                    valorTotal: Math.floor(Math.random() * 5000000) + 1000000,
                    status: state.status,
                    subStatus: state.subStatus,
                    comercial_id: comercial.id,
                    productor_id: productor.id,
                    responsableActividad: 'Coordinador Tigo',
                    descripcion: `Actividad de prueba generada para ${state.status}`,
                    createdAt: new Date(),
                    updatedAt: new Date(),
                });
            }
        }

        console.log(`Creating ${activitiesToCreate.length} activities...`);
        await Actividad.bulkCreate(activitiesToCreate);

        console.log('Seed completed successfully!');
        process.exit(0);
    } catch (error) {
        console.error('Unable to connect to the database:', error);
        process.exit(1);
    }
}

seed();
