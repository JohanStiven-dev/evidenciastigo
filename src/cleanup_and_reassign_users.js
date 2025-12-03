require('dotenv').config();
const { Sequelize, Op } = require('sequelize');
const sequelize = require('./config/db');
const User = require('./models/UserModel');
const Actividad = require('./models/ActividadModel');
const Bitacora = require('./models/BitacoraModel');
const RefreshToken = require('./models/RefreshTokenModel');
const Notificacion = require('./models/NotificacionModel');

const TARGET_USERS = [
    {
        email: 'comercial.tester@example.com',
        nombre: 'Comercial Tester',
        password: 'password12345',
        rol: 'Comercial',
        telefono: '3000000001'
    },
    {
        email: 'productor.tester@example.com',
        nombre: 'Productor Tester',
        password: 'password12345',
        rol: 'Productor',
        telefono: '3000000002'
    },
    {
        email: 'cliente_prueba@tigo.com.co',
        nombre: 'Cliente Prueba',
        password: 'password123',
        rol: 'Cliente',
        telefono: '3000000003'
    }
];

async function cleanupAndReassign() {
    const t = await sequelize.transaction();
    try {
        await sequelize.authenticate();
        console.log('Connection established.');

        const userIds = {};

        // 1. Find or Create Target Users
        for (const userData of TARGET_USERS) {
            const [user, created] = await User.findOrCreate({
                where: { email: userData.email },
                defaults: userData,
                transaction: t
            });

            // If user existed but password/details might be different, update them
            if (!created) {
                user.nombre = userData.nombre;
                user.password = userData.password; // Hook will hash this
                user.rol = userData.rol;
                await user.save({ transaction: t });
            }

            userIds[userData.rol] = user.id;
            console.log(`${created ? 'Created' : 'Updated'} User: ${userData.email} (ID: ${user.id})`);
        }

        const comercialId = userIds['Comercial'];
        const productorId = userIds['Productor'];
        const clienteId = userIds['Cliente']; // Not used for assignment yet but good to have

        // 2. Reassign All Activities
        console.log('Reassigning all activities to new Comercial and Productor...');
        const [updatedActivities] = await Actividad.update(
            {
                comercial_id: comercialId,
                productor_id: productorId
            },
            {
                where: {},
                transaction: t
            }
        );
        console.log(`Updated ${updatedActivities} activities.`);

        // 3. Reassign Bitacora (Logs)
        // To avoid FK errors when deleting old users, move all logs to the new Comercial user
        // This preserves the history text but changes the "actor" to the new user.
        console.log('Reassigning all logs to new Comercial...');
        const [updatedLogs] = await Bitacora.update(
            { user_id: comercialId },
            {
                where: {
                    user_id: { [Op.notIn]: Object.values(userIds) }
                },
                transaction: t
            }
        );
        console.log(`Updated ${updatedLogs} logs.`);

        // 4. Delete Dependent Data for Other Users
        console.log('Deleting dependent data (RefreshTokens, Notificaciones) for other users...');

        const usersToDeleteQuery = {
            email: { [Op.notIn]: TARGET_USERS.map(u => u.email) }
        };

        // Get IDs to delete
        const usersToDelete = await User.findAll({ where: usersToDeleteQuery, attributes: ['id'], transaction: t });
        const idsToDelete = usersToDelete.map(u => u.id);

        if (idsToDelete.length > 0) {
            await RefreshToken.destroy({ where: { user_id: idsToDelete }, transaction: t });
            await Notificacion.destroy({ where: { user_id: idsToDelete }, transaction: t });
            // Bitacora was already reassigned, but if any remain (e.g. created by others not in list?), delete them?
            // Better safe:
            await Bitacora.destroy({ where: { user_id: idsToDelete }, transaction: t });
        }

        // 5. Delete Other Users
        console.log('Deleting other users...');
        const deletedUsers = await User.destroy({
            where: { id: idsToDelete },
            transaction: t
        });
        console.log(`Deleted ${deletedUsers} old users.`);

        await t.commit();
        console.log('Cleanup and reassignment completed successfully!');
        process.exit(0);

    } catch (error) {
        await t.rollback();
        console.error('Error during cleanup:', error);
        process.exit(1);
    }
}

cleanupAndReassign();
