const db = require('../models/init-associations');
const { Notificacion } = db;
const { successResponse, errorResponse } = require('../utils/responseBuilder');

const getMyNotifications = async (req, res) => {
  try {
    const notificaciones = await Notificacion.findAll({
      where: { user_id: req.user.id },
      order: [['createdAt', 'DESC']],
      limit: 50,
    });
    successResponse(res, 'Notificaciones obtenidas con éxito', notificaciones);
  } catch (error) {
    console.error("Error fetching notifications:", error);
    errorResponse(res, 'Error en el servidor al obtener notificaciones', null, 500, error);
  }
};

const markAsRead = async (req, res) => {
  try {
    const { id } = req.params;
    const notification = await Notificacion.findByPk(id);

    if (!notification) {
      return errorResponse(res, 'Notificación no encontrada', null, 404);
    }

    if (notification.user_id !== req.user.id) {
      return errorResponse(res, 'No autorizado', null, 403);
    }

    notification.estado = 'leida';
    await notification.save();

    successResponse(res, 'Notificación marcada como leída', notification);
  } catch (error) {
    errorResponse(res, 'Error en el servidor al marcar la notificación', null, 500, error);
  }
};

const deleteNotification = async (req, res) => {
    try {
        const { id } = req.params;
        const notification = await Notificacion.findByPk(id);
    
        if (!notification) {
          return errorResponse(res, 'Notificación no encontrada', null, 404);
        }
    
        if (notification.user_id !== req.user.id) {
          return errorResponse(res, 'No autorizado', null, 403);
        }
    
        await notification.destroy();
    
        successResponse(res, 'Notificación eliminada');
      } catch (error) {
        errorResponse(res, 'Error en el servidor al eliminar la notificación', null, 500, error);
      }
};

module.exports = {
  getMyNotifications,
  markAsRead,
  deleteNotification,
};
