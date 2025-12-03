const jwt = require('jsonwebtoken');
const User = require('../models/UserModel');
const RefreshToken = require('../models/RefreshTokenModel');
const sequelize = require('../config/db');
const { successResponse, errorResponse } = require('../utils/responseBuilder');
const { JWT_SECRET, JWT_ACCESS_TOKEN_EXPIRATION, JWT_REFRESH_TOKEN_EXPIRATION } = require('../config/env');

// Helper function to parse expiration string (e.g., '1h', '7d') into seconds
const parseJwtExpiration = (expiresInString) => {
  const value = parseInt(expiresInString);
  const unit = expiresInString.replace(value, '');

  switch (unit) {
    case 's': return value;
    case 'm': return value * 60;
    case 'h': return value * 60 * 60;
    case 'd': return value * 24 * 60 * 60;
    default: return value; // Assume seconds if no unit or invalid unit
  }
};

// Helper function to generate JWTs and manage refresh tokens
const generateAuthTokens = async (user, ipAddress, transaction) => {
  const accessToken = jwt.sign({ id: user.id, rol: user.rol }, JWT_SECRET, { expiresIn: JWT_ACCESS_TOKEN_EXPIRATION });
  const refreshTokenValue = jwt.sign({ id: user.id, rol: user.rol }, JWT_SECRET, { expiresIn: JWT_REFRESH_TOKEN_EXPIRATION });

  const expiresAt = new Date();
  expiresAt.setSeconds(expiresAt.getSeconds() + parseJwtExpiration(JWT_REFRESH_TOKEN_EXPIRATION));

  await RefreshToken.create({
    user_id: user.id,
    token: refreshTokenValue,
    expires_at: expiresAt,
    created_by_ip: ipAddress,
  }, { transaction });

  return { accessToken, refreshToken: refreshTokenValue };
};

// @desc    Register a new user
// @route   POST /api/auth/register (for initial setup, can be removed later)
// @access  Public
const registerUser = async (req, res) => {
  const { nombre, email, password, rol, telefono } = req.body;
  const ipAddress = req.ip;
  const t = await sequelize.transaction();

  if (!nombre || !email || !password || !rol) {
    await t.rollback();
    return errorResponse(res, 'Please enter all required fields', null, 400);
  }

  try {
    const userExists = await User.findOne({ where: { email } }, { transaction: t });

    if (userExists) {
      await t.rollback();
      return errorResponse(res, 'User already exists', null, 400);
    }

    const user = await User.create({
      nombre,
      email,
      password,
      rol,
      telefono,
    }, { transaction: t });

    if (user) {
      const { accessToken, refreshToken } = await generateAuthTokens(user, ipAddress, t);
      await t.commit();
      successResponse(res, 'User registered successfully', {
        id: user.id,
        nombre: user.nombre,
        email: user.email,
        rol: user.rol,
        accessToken,
        refreshToken,
      }, 201);
    } else {
      await t.rollback();
      errorResponse(res, 'Invalid user data', null, 400);
    }
  } catch (error) {
    await t.rollback();
    errorResponse(res, `Server error: ${error.message}`);
  }
};

// @desc    Auth user & get token
// @route   POST /api/auth/login
// @access  Public
const login = async (req, res) => {
  const { email, password } = req.body;
  const ipAddress = req.ip;
  const t = await sequelize.transaction();

  if (!email || !password) {
    await t.rollback();
    return errorResponse(res, 'Please enter all fields', null, 400);
  }

  try {
    const user = await User.findOne({ where: { email } }, { transaction: t });

    if (user && (await user.comparePassword(password))) {
      const { accessToken, refreshToken } = await generateAuthTokens(user, ipAddress, t);
      await t.commit();
      successResponse(res, 'Logged in successfully', {
        id: user.id,
        nombre: user.nombre,
        email: user.email,
        rol: user.rol,
        accessToken,
        refreshToken,
      });
    } else {
      await t.rollback();
      errorResponse(res, 'Invalid credentials', null, 401);
    }
  } catch (error) {
    await t.rollback();
    errorResponse(res, `Server error: ${error.message}`);
  }
};

// @desc    Refresh access token
// @route   POST /api/auth/refresh
// @access  Public (with refresh token in body)
const refreshToken = async (req, res) => {
  const { refreshToken: oldRefreshTokenValue } = req.body;
  const ipAddress = req.ip;
  const t = await sequelize.transaction();

  if (!oldRefreshTokenValue) {
    await t.rollback();
    return errorResponse(res, 'No refresh token provided', null, 401);
  }

  try {
    const oldRefreshToken = await RefreshToken.findOne({
      where: { token: oldRefreshTokenValue },
      include: [{ model: User }],
    }, { transaction: t, lock: true });

    if (!oldRefreshToken || oldRefreshToken.revoked_at || oldRefreshToken.expires_at < new Date()) {
      // If token is invalid, revoked or expired, revoke all tokens for this user for security
      if (oldRefreshToken && oldRefreshToken.User) {
        await RefreshToken.update({ revoked_at: new Date() }, { where: { user_id: oldRefreshToken.User.id } }, { transaction: t });
      }
      await t.rollback();
      return errorResponse(res, 'Invalid or expired refresh token', null, 403);
    }

    // Revoke the old token (rotation)
    oldRefreshToken.revoked_at = new Date();
    oldRefreshToken.replaced_by_token = oldRefreshTokenValue; // Store the old token value for tracking
    await oldRefreshToken.save({ transaction: t });

    const user = oldRefreshToken.User;
    const { accessToken, refreshToken } = await generateAuthTokens(user, ipAddress, t);
    await t.commit();

    successResponse(res, 'Access token refreshed', {
      id: user.id,
      nombre: user.nombre,
      email: user.email,
      rol: user.rol,
      accessToken,
      refreshToken,
    });
  } catch (error) {
    await t.rollback();
    errorResponse(res, `Server error: ${error.message}`);
  }
};

// @desc    Get user profile
// @route   GET /api/auth/profile
// @access  Private
const getProfile = async (req, res) => {
  // req.user is set by the protect middleware
  successResponse(res, 'User profile fetched', req.user);
};

// @desc    Logout user (invalidate refresh token)
// @route   POST /api/auth/logout
// @access  Private (requires accessToken to identify user)
const logout = async (req, res) => {
  const { refreshToken: refreshTokenValue } = req.body; // Expect refresh token in body for explicit logout
  const t = await sequelize.transaction();

  if (!refreshTokenValue) {
    await t.rollback();
    return errorResponse(res, 'Refresh token is required for logout', null, 400);
  }

  try {
    const refreshToken = await RefreshToken.findOne({
      where: { token: refreshTokenValue, user_id: req.user.id },
    }, { transaction: t, lock: true });

    if (!refreshToken) {
      await t.rollback();
      return errorResponse(res, 'Refresh token not found or does not belong to user', null, 404);
    }

    refreshToken.revoked_at = new Date();
    await refreshToken.save({ transaction: t });
    await t.commit();

    successResponse(res, 'Logged out successfully');
  } catch (error) {
    await t.rollback();
    errorResponse(res, `Server error: ${error.message}`);
  }
};

module.exports = {
  registerUser,
  login,
  refreshToken,
  getProfile,
  logout,
};