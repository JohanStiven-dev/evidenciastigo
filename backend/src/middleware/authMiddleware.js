const jwt = require('jsonwebtoken');
const { errorResponse } = require('../utils/responseBuilder');
const User = require('../models/UserModel');
const { JWT_SECRET } = require('../config/env');

const protect = async (req, res, next) => {
  let token;

  if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
    try {
      token = req.headers.authorization.split(' ')[1];

      const decoded = jwt.verify(token, JWT_SECRET);

      req.user = await User.findByPk(decoded.id, { attributes: { exclude: ['password'] } });

      if (!req.user) {
        return errorResponse(res, 'Not authorized, user not found', null, 401);
      }

      next();
    } catch (error) {
      console.error(error);
      return errorResponse(res, 'Not authorized, token failed', null, 401);
    }
  }

  if (!token) {
    return errorResponse(res, 'Not authorized, no token', null, 401);
  }
};

const authorize = (...roles) => {
  return (req, res, next) => {
    if (!req.user || !roles.includes(req.user.rol)) {
      return errorResponse(res, `User role ${req.user ? req.user.rol : 'unknown'} is not authorized to access this route`, null, 403);
    }
    next();
  };
};

module.exports = {
  protect,
  authorize,
};
