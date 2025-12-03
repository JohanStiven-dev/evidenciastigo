require('dotenv').config();
const { Evidencia } = require('./src/models/init-associations');
const path = require('path');
const fs = require('fs');

async function checkEvidenceFiles() {
    try {
        const evidences = await Evidencia.findAll();
        console.log(`Checking ${evidences.length} evidences...`);

        for (const e of evidences) {
            const relativePath = e.archivo_path.startsWith('/') ? e.archivo_path.substring(1) : e.archivo_path;
            const absolutePath = path.join(process.cwd(), relativePath);

            try {
                await fs.promises.access(absolutePath);
                console.log(`[OK] ID: ${e.id} - Found at ${absolutePath}`);
            } catch (err) {
                console.log(`[MISSING] ID: ${e.id} - Not found at ${absolutePath}`);
            }
        }
    } catch (error) {
        console.error('Error:', error);
    } finally {
        process.exit();
    }
}

checkEvidenceFiles();
