const calendarioService = require('../services/calendarioService');
const { successResponse, errorResponse } = require('../utils/responseBuilder');

// @desc    Get calendar events (activities) for a date range
// @route   GET /api/calendario?from=...&to=...
// @access  Private
const getCalendarioEvents = async (req, res) => {
  const { from, to } = req.query;

  if (!from || !to) {
    return errorResponse(res, '\'from\' and \'to\' dates are required', null, 400);
  }

  try {
    const events = await calendarioService.getCalendarEvents(from, to, req.user.id, req.user.rol);
    successResponse(res, 'Calendar events fetched successfully', events);
  } catch (error) {
    errorResponse(res, `Server error: ${error.message}`);
  }
};

// @desc    Export single activity as ICS file
// @route   GET /api/calendario/:actividadId/ical
// @access  Private
const exportIcal = async (req, res) => {
  const { actividadId } = req.params; // Correctly read 'actividadId'

  try {
    const icsContent = await calendarioService.generateIcsForActivity(actividadId);

    if (!icsContent) {
      return errorResponse(res, 'Activity not found or cannot generate ICS', null, 404);
    }

    res.setHeader('Content-Type', 'text/calendar');
    res.setHeader('Content-Disposition', `attachment; filename="activity-${actividadId}.ics"`);
    res.send(icsContent);
  } catch (error) {
    errorResponse(res, `Server error: ${error.message}`);
  }
};

// @desc    Export personal user calendar feed as ICS file
// @route   GET /api/calendario/usuario/:userId.ics
// @access  Private
const exportUserIcalFeed = async (req, res) => {
  const { userId } = req.params;

  // Ensure the requesting user is the same as userId or is an Admin
  if (req.user.id !== parseInt(userId) && req.user.rol !== 'Administrador') {
    return errorResponse(res, 'Not authorized to access this user\'s calendar feed', null, 403);
  }

  try {
    const icsContent = await calendarioService.generateIcsFeedForUser(userId, req.user.rol);

    if (!icsContent) {
      return errorResponse(res, 'No activities found or cannot generate ICS feed', null, 404);
    }

    res.setHeader('Content-Type', 'text/calendar');
    res.setHeader('Content-Disposition', `attachment; filename="calendar-${userId}.ics"`);
    res.send(icsContent);
  } catch (error) {
    errorResponse(res, `Server error: ${error.message}`);
  }
};

module.exports = {
  getCalendarioEvents,
  exportIcal,
  exportUserIcalFeed,
};
