const { User } = require('../models/init-associations');
const { successResponse, errorResponse } = require('../utils/responseBuilder');

// @desc    Get users by role
// @route   GET /api/v2/users?rol=Productor
// @access  Private
const getUsersByRole = async (req, res) => {
    try {
        const { rol } = req.query;
        if (!rol) {
            return errorResponse(res, 'Role query parameter is required', null, 400);
        }

        const users = await User.findAll({
            where: { rol, estado: true },
            attributes: ['id', 'nombre', 'email', 'rol'],
        });

        successResponse(res, 'Users fetched successfully', users);
    } catch (error) {
        errorResponse(res, `Server error: ${error.message}`);
    }
};

module.exports = {
    getUsersByRole,
};
