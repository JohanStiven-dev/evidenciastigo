require('dotenv').config();
const { Sequelize } = require('sequelize');
const sequelize = require('./src/config/db');
const dashboardService = require('./src/services/dashboardService');

async function testDashboard() {
    try {
        await sequelize.authenticate();
        console.log('Connected.');

        // Simulate "Last 90 Days"
        // End Date: Today (2025-11-26)
        // Start Date: 90 days ago (2025-08-28)
        const endDate = new Date('2025-11-26T23:59:59.999Z');
        const startDate = new Date('2025-08-28T00:00:00.000Z');

        console.log('Testing getDashboardSummary...');
        const summary = await dashboardService.getDashboardSummary(startDate, endDate);

        console.log('Result Variation:', summary.variation);
        process.exit(0);
    } catch (error) {
        console.error('Error:', error);
        process.exit(1);
    }
}

testDashboard();
