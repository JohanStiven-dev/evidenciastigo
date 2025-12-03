require('dotenv').config();
const db = require('./src/models/init-associations');
const { User, sequelize } = db;

const usersToCreate = [
    {
        nombre: 'Data BullMarketing',
        email: 'data@bullmarketing.com.co',
        password: 'password1234',
        rol: 'Comercial',
        telefono: '3000000000'
    },
    {
        nombre: 'Santiago Parraga',
        email: 'Santiago.Parraga@bullmarketing.com.co',
        password: 'password1234',
        rol: 'Productor',
        telefono: '3000000000'
    },
    {
        nombre: 'Jeisson Prada',
        email: 'Jeisson.Prada@bullmarketing.com.co',
        password: 'password1234',
        rol: 'Cliente',
        telefono: '3000000000'
    }
];

async function createUsers() {
    try {
        await sequelize.authenticate();
        console.log('Connection has been established successfully.');

        for (const userData of usersToCreate) {
            const existingUser = await User.findOne({ where: { email: userData.email } });
            if (existingUser) {
                console.log(`User already exists: ${userData.email}`);
                // Optional: Update password if needed, but for now just skip
                continue;
            }

            await User.create(userData);
            console.log(`User created: ${userData.email} (${userData.rol})`);
        }

        console.log('All users processed.');
    } catch (error) {
        console.error('Error creating users:', error);
    } finally {
        await sequelize.close();
    }
}

createUsers();
