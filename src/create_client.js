require('dotenv').config();
const sequelize = require('./config/db');
const User = require('./models/UserModel');

async function createClient() {
    try {
        await sequelize.authenticate();

        const userData = {
            nombre: 'Cliente Prueba',
            email: 'cliente_prueba@tigo.com.co',
            password: 'password123',
            rol: 'Cliente',
            telefono: '3009998877',
            estado: true
        };

        const [user, created] = await User.findOrCreate({
            where: { email: userData.email },
            defaults: userData
        });

        if (created) {
            console.log(`SUCCESS: User created.`);
            console.log(`Email: ${user.email}`);
            console.log(`Password: ${userData.password}`);
            console.log(`Role: ${user.rol}`);
        } else {
            console.log(`INFO: User already exists.`);
            console.log(`Email: ${user.email}`);
            // We don't show password if it already exists as we didn't set it
        }

        process.exit(0);
    } catch (error) {
        console.error('Error creating user:', error);
        process.exit(1);
    }
}

createClient();
