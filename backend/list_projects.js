require('dotenv').config();
const { Proyecto, User } = require('./src/models/init-associations');

async function listProjects() {
    try {
        const projects = await Proyecto.findAll({
            include: [{ model: User, as: 'Cliente' }]
        });
        console.log(`Total Projects: ${projects.length}`);
        projects.forEach(p => {
            console.log(`ID: ${p.id}, Name: ${p.nombre}, Client ID: ${p.Cliente ? p.Cliente.id : 'None'}`);
        });
    } catch (error) {
        console.error('Error:', error);
    } finally {
        process.exit();
    }
}

listProjects();
