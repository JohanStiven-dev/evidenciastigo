require('dotenv').config();
const { User } = require('./src/models/init-associations');

async function checkUsers() {
    try {
        const users = await User.findAll();
        console.log(`Total Users: ${users.length}`);
        users.forEach(u => {
            console.log(`ID: ${u.id}, Name: ${u.nombre}, Role: ${u.rol}, Email: ${u.email}`);
        });
    } catch (error) {
        console.error('Error:', error);
    } finally {
        process.exit();
    }
}

checkUsers();
