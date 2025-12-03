require('dotenv').config();
const db = require('./src/models/init-associations');
const { Catalogo, sequelize } = db;

const catalogData = [
    // Segmentos
    { tipo: 'segmento', valor: 'Pymes', orden: 1 },
    { tipo: 'segmento', valor: 'Empresas', orden: 2 },
    { tipo: 'segmento', valor: 'Gobierno', orden: 3 },
    { tipo: 'segmento', valor: 'Hogares', orden: 4 },

    // Clase Presupuesto
    { tipo: 'clase_ppto', valor: 'Opex', orden: 1 },
    { tipo: 'clase_ppto', valor: 'Capex', orden: 2 },

    // Canales
    { tipo: 'canal', valor: 'Directo', orden: 1 },
    { tipo: 'canal', valor: 'Indirecto', orden: 2 },
    { tipo: 'canal', valor: 'Retail', orden: 3 },
    { tipo: 'canal', valor: 'Televentas', orden: 4 },

    // Ciudades
    { tipo: 'ciudad', valor: 'Bogotá', orden: 1 },
    { tipo: 'ciudad', valor: 'Medellín', orden: 2 },
    { tipo: 'ciudad', valor: 'Cali', orden: 3 },
    { tipo: 'ciudad', valor: 'Barranquilla', orden: 4 },
    { tipo: 'ciudad', valor: 'Bucaramanga', orden: 5 },
    { tipo: 'ciudad', valor: 'Cartagena', orden: 6 },
    { tipo: 'ciudad', valor: 'Pereira', orden: 7 },
];

async function seedCatalogs() {
    try {
        await sequelize.authenticate();
        console.log('Connection has been established successfully.');

        for (const item of catalogData) {
            const [catalogo, created] = await Catalogo.findOrCreate({
                where: { tipo: item.tipo, valor: item.valor },
                defaults: item
            });
            console.log(`Catalog item ${created ? 'created' : 'found'}: ${item.tipo} - ${item.valor}`);
        }

        console.log('All catalog items processed.');
    } catch (error) {
        console.error('Error seeding catalogs:', error);
    } finally {
        await sequelize.close();
    }
}

seedCatalogs();
