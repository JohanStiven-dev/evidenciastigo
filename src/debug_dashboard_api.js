require('dotenv').config();
const axios = require('axios');

const BASE_URL = 'http://localhost:3000/api/v2';

async function debugApi() {
    try {
        // 1. Login
        console.log('Logging in...');
        const loginRes = await axios.post(`${BASE_URL}/auth/login`, {
            email: 'comercial@tigo.com.co',
            password: 'password123'
        });
        const token = loginRes.data.data.accessToken;
        const userId = loginRes.data.data.id;
        console.log(`Login successful. User ID: ${userId}`);

        const headers = { Authorization: `Bearer ${token}` };

        // Check DB directly for ownership
        const { Sequelize } = require('sequelize');
        const sequelize = require('./config/db');
        const Actividad = require('./models/ActividadModel');

        await sequelize.authenticate();
        const count = await Actividad.count({ where: { comercial_id: userId } });
        console.log(`Activities owned by User ${userId}: ${count}`);

        const totalCount = await Actividad.count();
        console.log(`Total Activities in DB: ${totalCount}`);

        if (totalCount > 0) {
            const sample = await Actividad.findOne();
            console.log(`Sample Activity Owner: ${sample.comercial_id}`);
        }

        // 2. Test Upcoming Activities
        const startDate = new Date().toISOString().split('T')[0];
        const endDate = new Date(new Date().setDate(new Date().getDate() + 30)).toISOString().split('T')[0];
        console.log(`\nFetching Upcoming Activities (${startDate} to ${endDate})...`);

        const upcomingRes = await axios.get(`${BASE_URL}/actividades`, {
            headers,
            params: {
                fecha_desde: startDate,
                fecha_hasta: endDate,
                sort: 'fecha',
                order: 'asc',
                limit: 10
            }
        });
        console.log('Upcoming Count:', upcomingRes.data.data.data.length);
        if (upcomingRes.data.data.data.length > 0) {
            console.log('First Upcoming:', JSON.stringify(upcomingRes.data.data.data[0], null, 2));
        } else {
            console.log('Upcoming Data:', JSON.stringify(upcomingRes.data.data, null, 2));
        }

        // 3. Test Recent Activities
        console.log('\nFetching Recent Activities...');
        const recentRes = await axios.get(`${BASE_URL}/actividades`, {
            headers,
            params: {
                sort: 'createdAt',
                order: 'desc',
                limit: 5
            }
        });
        console.log('Recent Count:', recentRes.data.data.data.length);
        if (recentRes.data.data.data.length > 0) {
            console.log('First Recent:', JSON.stringify(recentRes.data.data.data[0], null, 2));
        } else {
            console.log('Recent Data:', JSON.stringify(recentRes.data.data, null, 2));
        }

    } catch (error) {
        if (error.code === 'ECONNREFUSED') {
            console.error('Connection refused. Is the backend server running on port 3000?');
        } else {
            console.error('Error:', error.response ? error.response.data : error.message);
            console.error('Full Error:', error);
        }
    }
}

debugApi();
