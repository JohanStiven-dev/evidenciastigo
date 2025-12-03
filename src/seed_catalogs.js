require('dotenv').config();
const sequelize = require('./config/db');
const Catalogo = require('./models/CatalogoModel');

const CATALOG_DATA = {
    ciudad: ['Bogotá', 'Medellín', 'Cali', 'Barranquilla', 'Cartagena', 'Bucaramanga'],
    canal: ['Tiendas', 'Kioscos', 'Mayoristas', 'TAT', 'Grandes Superficies'],
    segmento: ['Masivo', 'Pymes', 'Corporativo'],
    clase_ppto: ['Opex', 'Capex']
};

async function seedCatalogs() {
    try {
        await sequelize.authenticate();
        console.log('Connection has been established successfully.');

        console.log('Seeding catalogs...');

        for (const [tipo, valores] of Object.entries(CATALOG_DATA)) {
            for (const valor of valores) {
                await Catalogo.findOrCreate({
                    where: { tipo, valor },
                    defaults: { tipo, valor, activo: true }
                });
            }
        }

        console.log('Catalog seeding completed.');
        process.exit(0);
    } catch (error) {
        console.error('Unable to seed catalogs:', error);
        process.exit(1);
    }
}

seedCatalogs();
