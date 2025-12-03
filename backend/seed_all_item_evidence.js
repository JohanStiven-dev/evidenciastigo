require('dotenv').config({ path: './backend/.env' });
// const sequelize = require('./src/config/db'); // No longer needed here
const fs = require('fs').promises;
const path = require('path');
const { Op } = require('sequelize'); // Import Op directly

// Import the associated models and sequelize instance
const db = require('./src/models/init-associations'); 
const sequelizeInstance = db.sequelize; // Get the sequelize instance from the exported db object

const Actividad = db.Actividad;
const Presupuesto = db.Presupuesto;
const PresupuestoItem = db.PresupuestoItem;
const Evidencia = db.Evidencia;

const seedAllItemEvidence = async () => {
  try {
    await sequelizeInstance.authenticate();
    console.log('Database connection has been established successfully.');

    // 1. Define paths
    const sourceImagePath = path.resolve(__dirname, '../evidencia.png'); // Path to the user-provided image
    const uploadsBasePath = path.resolve(__dirname, 'uploads/actividades');

    // Ensure the source image exists
    try {
      await fs.access(sourceImagePath);
      console.log('Source image evidencia.png found.');
    } catch (error) {
      console.error('❌ Error: evidencia.png not found in the project root. Please place it there.');
      return;
    }

    // 2. Fetch all Activities with their Presupuestos, PresupuestoItems, and existing Evidencias
    const activities = await Actividad.findAll({
      include: [{
        model: Presupuesto,
        include: [{
          model: PresupuestoItem,
          include: [{
            model: Evidencia,
            required: false, // Don't require evidence to exist
          }]
        }]
      }]
    });

    if (activities.length === 0) {
      console.log('No activities found to process.');
      return;
    }
    console.log(`Found ${activities.length} activities.`);

    let evidenceCreatedCount = 0;

    for (const actividad of activities) {
      if (actividad.Presupuesto && actividad.Presupuesto.PresupuestoItems) {
        for (const item of actividad.Presupuesto.PresupuestoItems) {
          // Check if this PresupuestoItem already has evidence
          if (item.Evidencias && item.Evidencias.length > 0) {
            console.log(`PresupuestoItem ${item.id} (Activity ${actividad.id}) already has evidence. Skipping.`);
            continue;
          }

          // Define destination path
          const destDir = path.join(uploadsBasePath, String(actividad.id), 'evidencias'); // Organized by actividadId
          await fs.mkdir(destDir, { recursive: true });

          const destFileName = `evidencia_item_${item.id}_${Date.now()}.png`;
          const destPath = path.join(destDir, destFileName);

          // Copy the file
          await fs.copyFile(sourceImagePath, destPath);
          console.log(`Copied evidencia.png to: ${destPath} for PresupuestoItem ${item.id} (Activity ${actividad.id})`);

          // Create Evidencia record in DB
          const fileStats = await fs.stat(destPath);
          await Evidencia.create({
            presupuesto_item_id: item.id,
            tipo: 'foto_actividad',
            archivo_path: destPath, // Storing absolute path
            archivo_nombre: destFileName,
            mime: 'image/png',
            peso_bytes: fileStats.size,
            comentario: `Evidencia para ${item.item} de Actividad ${actividad.codigos}`,
          });
          evidenceCreatedCount++;
        }
      }
    }

    console.log(`\n✅ Seeding complete. Created ${evidenceCreatedCount} new evidence records with real image files.`);

  } catch (error) {
    console.error('❌ Error seeding real evidence to all items:', error);
  } finally {
    await sequelize.close();
    console.log('Database connection closed.');
  }
};

seedAllItemEvidence();