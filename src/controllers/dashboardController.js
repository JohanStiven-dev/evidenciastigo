const dashboardService = require('../services/dashboardService');
const { successResponse, errorResponse } = require('../utils/responseBuilder');
const { ROLES } = require('../utils/constants');

// @desc    Get dashboard summary KPIs
// @route   GET /api/dashboard/resumen?fecha_desde=...&fecha_hasta=...
// @access  Private
const getDashboardSummary = async (req, res) => {
  const { fecha_desde, fecha_hasta } = req.query;

  if (!fecha_desde || !fecha_hasta) {
    return errorResponse(res, '\'fecha_desde\' and \'fecha_hasta\' are required', null, 400);
  }

  try {
    // RBAC: Cliente can only see their own data (not implemented yet)
    // For now, Admin, Comercial, Productor can see general summary

    const summary = await dashboardService.getDashboardSummary(fecha_desde, fecha_hasta);
    successResponse(res, 'Dashboard summary fetched successfully', summary);
  } catch (error) {
    errorResponse(res, `Server error: ${error.message}`);
  }
};

// @desc    Export activities report as XLSX
// @route   GET /api/reportes/actividades.xlsx?filtros...
// @access  Private
const getActivitiesReportXLSX = async (req, res) => {
  try {
    const buffer = await dashboardService.getActivitiesReportXLSX(req.query);

    res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
    res.setHeader('Content-Disposition', 'attachment; filename="actividades.xlsx"');
    res.send(buffer);
  } catch (error) {
    errorResponse(res, `Server error: ${error.message}`);
  }
};

// @desc    Export budgets report as CSV
// @route   GET /api/reportes/presupuestos.csv?fecha_desde=...&fecha_hasta=...
// @access  Private
const getPresupuestosReportCSV = async (req, res) => {
  const { fecha_desde, fecha_hasta } = req.query;

  if (!fecha_desde || !fecha_hasta) {
    return errorResponse(res, '\'fecha_desde\' and \'fecha_hasta\' are required', null, 400);
  }

  try {
    // RBAC: Only Admin or specific roles can download reports
    if (req.user.rol !== ROLES.ADMIN && req.user.rol !== ROLES.CLIENTE) {
      return errorResponse(res, 'Not authorized to download this report', null, 403);
    }

    const csvData = await dashboardService.getPresupuestosReportCSV(fecha_desde, fecha_hasta);

    res.setHeader('Content-Type', 'text/csv');
    res.setHeader('Content-Disposition', 'attachment; filename="presupuestos.csv"');
    res.send(csvData);
  } catch (error) {
    errorResponse(res, `Server error: ${error.message}`);
  }
};

// @desc    Export activity evidences as a ZIP file
// @route   GET /api/reportes/actividad/:id/evidencias.zip
// @access  Private
const getEvidenciasZipByActividadId = async (req, res) => {
  const { id } = req.params; // Activity ID

  try {
    // RBAC: Ensure user has permission to view/download evidences for this activity
    // This logic should be more granular, checking activity ownership/association
    // For now, roles allowed in route definition are sufficient.

    const zipStream = await dashboardService.getEvidenciasZipByActividadId(id);

    res.setHeader('Content-Type', 'application/zip');
    res.setHeader('Content-Disposition', `attachment; filename="evidencias_actividad_${id}.zip"`);
    zipStream.pipe(res);
  } catch (error) {
    errorResponse(res, `Server error: ${error.message}`);
  }
};

module.exports = {
  getDashboardSummary,
  getActivitiesReportXLSX,
  getPresupuestosReportCSV,
  getEvidenciasZipByActividadId,
};
