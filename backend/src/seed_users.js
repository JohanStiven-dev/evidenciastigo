require('dotenv').config();
const sequelize = require('./config/db');
const User = require('./models/UserModel');

const usersToCreate = [
    {
        nombre: 'Usuario Cliente',
        email: 'cliente@tigo.com.co',
        password: 'password123',
        rol: 'Cliente',
        telefono: '3001234567',
        estado: true
    },
    {
        nombre: 'Usuario Productor',
        email: 'productor@tigo.com.co',
        password: 'password123',
        rol: 'Productor',
        telefono: '3007654321',
        estado: true
    },
    {
        nombre: 'Usuario Comercial',
        email: 'comercial@tigo.com.co',
        password: 'password123',
        rol: 'Comercial',
        telefono: '3001112233',
        estado: true
    }
];

async function seedUsers() {
    try {
        await sequelize.authenticate();
        console.log('Connection has been established successfully.');

        for (const userData of usersToCreate) {
            const [user, created] = await User.findOrCreate({
                where: { email: userData.email },
                defaults: userData
            });

            if (created) {
                console.log(`User created: ${user.email} (${user.rol})`);
            } else {
                console.log(`User already exists: ${user.email} (${user.rol})`);
                // Optional: Update password if needed, but skipping for now to preserve existing data
            }
        }

        console.log('Seeding completed.');
        process.exit(0);
    } catch (error) {
        console.error('Unable to connect to the database or seed users:', error);
        process.exit(1);
    }
}

seedUsers();
