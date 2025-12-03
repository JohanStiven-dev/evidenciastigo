const sequelize = require('../config/db');
const { successResponse, errorResponse } = require('../utils/responseBuilder');
const os = require('os');
const path = require('path');
const fs = require('fs').promises;

// Store app start time
const appStartTime = new Date();

// @desc    Get system health status
// @route   GET /api/health
// @access  Public
const getHealth = async (req, res) => {
  try {
    // Check database connection
    await sequelize.authenticate();
    const dbStatus = 'ok';

    // Calculate uptime
    const uptimeSeconds = Math.floor((new Date() - appStartTime) / 1000);

    // Check queue status (placeholder for now)
    const queueStatus = 'pending'; // TODO: Implement actual queue check

    successResponse(res, 'System health status', {
      db: dbStatus,
      queue: queueStatus,
      uptime_s: uptimeSeconds,
    });
  } catch (error) {
    errorResponse(res, `Health check failed: ${error.message}`, { db: 'error', queue: 'pending' }, 500);
  }
};

// @desc    Get application version
// @route   GET /api/version
// @access  Public
const getVersion = async (req, res) => {
  try {
    const packageJsonPath = path.join(__dirname, '../../package.json');
    const packageJson = JSON.parse(await fs.readFile(packageJsonPath, 'utf-8'));

    const appVersion = packageJson.version || 'N/A';
    const commitHash = process.env.COMMIT_HASH || 'N/A'; // Assuming COMMIT_HASH env var is set during deploy
    const environment = process.env.NODE_ENV || 'development';

    successResponse(res, 'Application version info', {
      version: appVersion,
      commit: commitHash,
      env: environment,
    });
  } catch (error) {
    errorResponse(res, `Failed to get version info: ${error.message}`, null, 500);
  }
};

module.exports = {
  getHealth,
  getVersion,
};
