const fs = require('fs').promises;
const path = require('path');
const { UPLOAD_PATH } = require('../config/env');
const PresupuestoItem = require('../models/PresupuestoItemModel'); // New import
const Presupuesto = require('../models/PresupuestoModel'); // New import

const saveFile = async (file, entityId, type) => {
  try {
    // Simplified: entityId is always passed as ActividadId from controllers
    const actividadId = entityId;

    const yearMonth = new Date().toISOString().substring(0, 7); // YYYY-MM
    const uploadDir = path.join(UPLOAD_PATH, 'actividades', String(actividadId), type === 'documentos' ? 'docs' : 'evidencias', yearMonth);

    await fs.mkdir(uploadDir, { recursive: true });

    const uniqueFilename = `${file.filename}-${Date.now()}${path.extname(file.originalname)}`;
    const filePath = path.join(uploadDir, uniqueFilename);

    await fs.rename(file.path, filePath); // Move the file from temp to permanent location

    // Return relative path for DB storage (e.g., /uploads/actividades/...)
    // UPLOAD_PATH is usually 'uploads' or similar relative to root.
    // We need to construct the URL path.
    // Assuming UPLOAD_PATH resolves to something inside 'uploads' folder.
    // Let's assume we want to store '/uploads/actividades/...'

    const relativePath = `/uploads/actividades/${actividadId}/${type === 'documentos' ? 'docs' : 'evidencias'}/${yearMonth}/${uniqueFilename}`;

    return {
      archivo_path: relativePath, // Store relative path!
      archivo_nombre: uniqueFilename,
      mime: file.mimetype,
      peso_bytes: file.size,
      tipo: type,
    };
  } catch (error) {
    console.error('Error saving file:', error);
    throw new Error('Could not save file');
  }
};

const deleteFile = async (filePath) => {
  try {
    await fs.unlink(filePath);
    return true;
  } catch (error) {
    console.error('Error deleting file:', error);
    throw new Error('Could not delete file');
  }
};

module.exports = {
  saveFile,
  deleteFile,
};
