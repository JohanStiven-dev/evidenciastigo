const { Op } = require('sequelize');
const sequelize = require('sequelize');
const db = require('../models/init-associations');
const {
  Actividad,
  Presupuesto,
  PresupuestoItem,
  Evidencia,
  User,
} = db;
const { STATUS, SUB_STATUS } = require('../utils/constants');
const archiver = require('archiver');
const fs = require('fs');
const path = require('path');
const { UPLOAD_PATH } = require('../config/env');
const ExcelJS = require('exceljs');

const getDashboardSummary = async (startDateStr, endDateStr) => {
  const startDate = new Date(startDateStr);
  const endDate = new Date(endDateStr);

  const whereClause = {
    fecha: {
      [Op.between]: [startDate, endDate],
    },
  };

  // --- Previous Period Calculation ---
  const diff = new Date(endDate) - new Date(startDate);
  const prevEndDate = new Date(startDate - 1);
  const prevStartDate = new Date(prevEndDate - diff);
  const prevWhereClause = {
    fecha: {
      [Op.between]: [prevStartDate, prevEndDate],
    },
  };

  // --- KPIs for Current and Previous Period ---
  const calculateKpis = async (clause) => {
    const totalActividades = await Actividad.count({ where: clause });
    const totalPresupuestoEjecutado = await Presupuesto.sum('total_cop', {
      include: [{ model: Actividad, where: { ...clause, status: { [Op.in]: [STATUS.EN_CURSO, STATUS.FINALIZADA] } }, required: true }],
    });
    const actividadesConEvidenciasCompletas = await Actividad.count({
      where: {
        ...clause,
        [Op.or]: [
          { status: STATUS.FINALIZADA, sub_status: SUB_STATUS.COMPLETADO },
          { status: STATUS.EN_CURSO, sub_status: SUB_STATUS.CARGANDO_EVIDENCIAS }
        ]
      },
    });
    return {
      totalActividades: totalActividades || 0,
      totalPresupuestoEjecutado: totalPresupuestoEjecutado || 0,
      actividadesConEvidenciasCompletas: actividadesConEvidenciasCompletas || 0,
    };
  };

  const currentKpis = await calculateKpis(whereClause);
  const previousKpis = await calculateKpis(prevWhereClause);

  // --- Calculate Variations ---
  const calculateVariation = (current, previous) => {
    if (previous === 0) return current > 0 ? 100 : 0;
    return ((current - previous) / previous) * 100;
  };

  const variation = {
    totalActividades: calculateVariation(currentKpis.totalActividades, previousKpis.totalActividades),
    totalPresupuestoEjecutado: calculateVariation(currentKpis.totalPresupuestoEjecutado, previousKpis.totalPresupuestoEjecutado),
    actividadesConEvidenciasCompletas: calculateVariation(currentKpis.actividadesConEvidenciasCompletas, previousKpis.actividadesConEvidenciasCompletas),
  };

  // --- Time-based Breakdown ---
  const now = new Date();
  const todayStart = new Date(now.setHours(0, 0, 0, 0));
  const todayEnd = new Date(now.setHours(23, 59, 59, 999));
  const weekStart = new Date(todayStart.setDate(todayStart.getDate() - todayStart.getDay()));
  const monthStart = new Date(now.getFullYear(), now.getMonth(), 1);

  const breakdown = {
    today: await Actividad.count({ where: { fecha: { [Op.between]: [todayStart, todayEnd] } } }),
    thisWeek: await Actividad.count({ where: { fecha: { [Op.gte]: weekStart } } }),
    thisMonth: await Actividad.count({ where: { fecha: { [Op.gte]: monthStart } } }),
  };

  // --- Other KPIs (as before) ---
  const actividadesByStatus = await Actividad.findAll({
    attributes: ['status', [sequelize.fn('COUNT', sequelize.col('id')), 'count']],
    where: whereClause,
    group: ['status'],
    raw: true,
  });
  const totalPresupuestoPlanificado = await Presupuesto.sum('total_cop', {
    include: [{ model: Actividad, where: { ...whereClause, status: { [Op.in]: [STATUS.CONFIRMADA, STATUS.EN_CURSO, STATUS.FINALIZADA] } }, required: true }],
  });
  const alertasProgramadasSinPresupuesto = await Actividad.count({
    where: { ...whereClause, status: STATUS.CONFIRMADA, '$Presupuesto.id$': null },
    include: [{
      model: Presupuesto,
      as: 'Presupuesto',
      required: false,
      attributes: [],
    }],
  });

  return {
    actividadesByStatus,
    totalActividades: currentKpis.totalActividades,
    totalPresupuestoEjecutado: currentKpis.totalPresupuestoEjecutado,
    totalPresupuestoPlanificado: totalPresupuestoPlanificado || 0,
    actividadesConEvidenciasCompletas: currentKpis.actividadesConEvidenciasCompletas,
    alertasProgramadasSinPresupuesto: alertasProgramadasSinPresupuesto || 0,
    breakdown,
    variation,
  };
};

const getActivitiesReportXLSX = async (filters) => {
  const whereClause = {};
  if (filters.ciudad) whereClause.ciudad = filters.ciudad;
  if (filters.canal) whereClause.canal = filters.canal;
  if (filters.semana) whereClause.semana = filters.semana;
  if (filters.status) whereClause.status = filters.status;
  if (filters.sub_status) whereClause.sub_status = filters.sub_status;

  const actividades = await Actividad.findAll({
    where: whereClause,
    include: [
      { model: User, as: 'Comercial', attributes: ['nombre'] },
      { model: User, as: 'Productor', attributes: ['nombre'] },
      {
        model: Presupuesto,
        as: 'Presupuesto',
        include: [{
          model: PresupuestoItem,
          include: [{ model: Evidencia }]
        }]
      },
    ],
    order: [['fecha', 'DESC']],
  });

  const workbook = new ExcelJS.Workbook();
  const worksheet = workbook.addWorksheet('Reporte Detallado');

  // Styles
  const headerStyle = {
    font: { bold: true, color: { argb: 'FFFFFFFF' }, size: 12 },
    fill: { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FF00377B' } }, // Tigo Blue
    alignment: { horizontal: 'center', vertical: 'middle' },
    border: { top: { style: 'thin' }, left: { style: 'thin' }, bottom: { style: 'thin' }, right: { style: 'thin' } }
  };

  const subHeaderStyle = {
    font: { bold: true, color: { argb: 'FF00377B' } },
    fill: { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFEAECF0' } }, // Light Gray
    border: { top: { style: 'thin' }, left: { style: 'thin' }, bottom: { style: 'thin' }, right: { style: 'thin' } }
  };

  const cellStyle = {
    border: { top: { style: 'thin' }, left: { style: 'thin' }, bottom: { style: 'thin' }, right: { style: 'thin' } },
    alignment: { vertical: 'middle', wrapText: true }
  };

  // Columns Setup (We'll use explicit row adding instead of defining columns globally to handle the dynamic structure)
  worksheet.columns = [
    { key: 'A', width: 20 }, // Label / Item
    { key: 'B', width: 30 }, // Value / Desc
    { key: 'C', width: 20 }, // Extra / Qty
    { key: 'D', width: 20 }, // Cost
    { key: 'E', width: 20 }, // Subtotal
    { key: 'F', width: 20 }, // Evidence Image
    { key: 'G', width: 40 }, // Evidence Link
  ];

  let currentRow = 1;

  for (const actividad of actividades) {
    // --- Activity Header Block ---
    const startRow = currentRow;

    // Title Row
    worksheet.mergeCells(`A${currentRow}:G${currentRow}`);
    const titleCell = worksheet.getCell(`A${currentRow}`);
    titleCell.value = `ACTIVIDAD: ${actividad.codigos} - ${actividad.agencia}`;
    titleCell.style = headerStyle;
    currentRow++;

    // Details Rows
    const details = [
      ['Fecha:', actividad.fecha, 'Ciudad:', actividad.ciudad],
      ['Responsable:', actividad.responsable_actividad, 'Punto de Venta:', actividad.punto_venta],
      ['Comercial:', actividad.Comercial?.nombre || 'N/A', 'Productor:', actividad.Productor?.nombre || 'N/A'],
      ['Estado:', actividad.status, 'Sub-Estado:', actividad.sub_status || 'N/A'],
      ['Presupuesto Total:', actividad.Presupuesto?.total_cop || 0, '', '']
    ];

    details.forEach(row => {
      const r = worksheet.getRow(currentRow);
      r.values = [row[0], row[1], row[2], row[3]];
      r.getCell(1).font = { bold: true };
      r.getCell(3).font = { bold: true };
      r.eachCell((cell) => { cell.border = cellStyle.border; });
      if (typeof row[1] === 'number') r.getCell(2).numFmt = '"$"#,##0.00';
      currentRow++;
    });

    currentRow++; // Spacer

    // --- Budget Items Table ---
    if (actividad.Presupuesto && actividad.Presupuesto.PresupuestoItems && actividad.Presupuesto.PresupuestoItems.length > 0) {
      // Table Header
      const headerRow = worksheet.getRow(currentRow);
      headerRow.values = ['Ítem', 'Comentario', 'Cantidad', 'Costo Unitario', 'Subtotal', 'Evidencia (Foto)', 'Enlace Descarga'];
      headerRow.eachCell((cell) => { cell.style = subHeaderStyle; });
      currentRow++;

      // Items
      for (const item of actividad.Presupuesto.PresupuestoItems) {
        const itemRow = worksheet.getRow(currentRow);
        itemRow.values = [
          item.item,
          item.comentario || '',
          item.cantidad,
          item.costo_unitario_cop,
          item.subtotal_cop,
          '', // Placeholder for Image
          ''  // Placeholder for Link
        ];

        itemRow.height = 60; // Make row taller for image
        itemRow.eachCell((cell) => { cell.style = cellStyle; });
        itemRow.getCell(4).numFmt = '"$"#,##0.00';
        itemRow.getCell(5).numFmt = '"$"#,##0.00';

        // Handle Evidences
        if (item.Evidencia && item.Evidencia.length > 0) {
          const evidencia = item.Evidencia[0]; // Take the first one for the main display
          const links = item.Evidencia.map(e => `http://localhost:3000/api/v2/evidencias/${e.id}/download`).join('\n');

          itemRow.getCell(7).value = { text: 'Descargar Evidencias', hyperlink: links.split('\n')[0], tooltip: 'Click para descargar' };
          // Note: Excel only supports one hyperlink per cell easily. We link the first one.
          // Alternatively, we could put the text URL.
          itemRow.getCell(7).value = links; // Just put the text links for simplicity and robustness

          // Embed Image
          const imagePath = path.join(UPLOAD_PATH, evidencia.archivo_path);
          if (fs.existsSync(imagePath)) {
            try {
              const imageId = workbook.addImage({
                filename: imagePath,
                extension: path.extname(imagePath).substring(1),
              });
              worksheet.addImage(imageId, {
                tl: { col: 5, row: currentRow - 1 }, // 0-indexed cols/rows for positioning? No, exceljs uses 0-index for tl
                ext: { width: 80, height: 80 },
                editAs: 'oneCell'
              });
            } catch (err) {
              console.error('Error embedding image:', err);
            }
          }
        } else {
          itemRow.getCell(6).value = 'Sin Evidencia';
        }
        currentRow++;
      }
    } else {
      worksheet.getRow(currentRow).values = ['Sin presupuesto asignado'];
      currentRow++;
    }

    currentRow += 2; // Spacer between activities
  }

  return workbook.xlsx.writeBuffer();
};

const getPresupuestosReportCSV = async (startDate, endDate) => {
  const whereClause = {
    createdAt: {
      [Op.between]: [startDate, endDate],
    },
  };

  const presupuestos = await Presupuesto.findAll({
    where: whereClause,
    include: [
      { model: Actividad, attributes: ['codigos', 'agencia'] },
      { model: PresupuestoItem },
    ],
  });

  let csv = 'ID Presupuesto,Código Actividad,Agencia,Total COP,Estado Presupuesto,Item,Cantidad,Costo Unitario,Subtotal,Impuesto,Comentario\n';

  presupuestos.forEach(presupuesto => {
    const actividadCodigos = presupuesto.Actividad ? presupuesto.Actividad.codigos : '';
    const actividadAgencia = presupuesto.Actividad ? presupuesto.Actividad.agencia : '';

    if (presupuesto.PresupuestoItems && presupuesto.PresupuestoItems.length > 0) {
      presupuesto.PresupuestoItems.forEach(item => {
        csv += `"${presupuesto.id}","${actividadCodigos}","${actividadAgencia}","${presupuesto.total_cop}","${presupuesto.estado_presupuesto}",`;
        csv += `"${item.item}","${item.cantidad}","${item.costo_unitario_cop}","${item.subtotal_cop}","${item.impuesto_cop || 0}","${item.comentario || ''}"\n`;
      });
    } else {
      csv += `"${presupuesto.id}","${actividadCodigos}","${actividadAgencia}","${presupuesto.total_cop}","${presupuesto.estado_presupuesto}",,,,,,\n`;
    }
  });

  return csv;
};

const getEvidenciasZipByActividadId = async (actividadId) => {
  const evidencias = await Evidencia.findAll({
    where: { actividad_id: actividadId },
  });

  if (evidencias.length === 0) {
    throw new Error('No evidences found for this activity');
  }

  const archive = archiver('zip', {
    zlib: { level: 9 } // Sets the compression level.
  });

  // Pipe archive data to a temporary file or directly to response
  // For direct response, return the archive stream
  evidencias.forEach(evidencia => {
    const filePath = path.join(UPLOAD_PATH, evidencia.archivo_path); // Assuming archivo_path is relative to UPLOAD_PATH
    if (fs.existsSync(filePath)) {
      archive.file(filePath, { name: evidencia.archivo_nombre });
    } else {
      console.warn(`File not found for evidence ID ${evidencia.id}: ${filePath}`);
    }
  });

  archive.finalize();
  return archive; // Return the archive stream
};

module.exports = {
  getDashboardSummary,
  getActivitiesReportXLSX,
  getPresupuestosReportCSV,
  getEvidenciasZipByActividadId,
};
