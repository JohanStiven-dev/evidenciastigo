require('dotenv').config();
const { Evidencia } = require('./src/models/init-associations');

async function checkEvidencePaths() {
    try {
        const evidences = await Evidencia.findAll();
        console.log(`Total Evidences: ${evidences.length}`);
        evidences.forEach(e => {
            console.log(`ID: ${e.id}, Path: ${e.archivo_path}, Name: ${e.archivo_nombre}`);
        });
    } catch (error) {
        console.error('Error:', error);
    } finally {
        process.exit();
    }
}

checkEvidencePaths();
