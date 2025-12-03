const request = require('supertest');
const app = require('../src/app');
const { User, Actividad, Presupuesto, PresupuestoItem, Evidencia, Proyecto } = require('../src/models/init-associations');
const path = require('path');
const fs = require('fs');

// Mock file for upload
const mockFilePath = path.join(__dirname, 'test_image.jpg');
if (!fs.existsSync(mockFilePath)) {
    fs.writeFileSync(mockFilePath, 'fake image content');
}

describe('Core Workflow Integration Test', () => {
    let comercialToken;
    let productorToken;
    let clienteToken;
    let actividadId;
    let presupuestoItemId;
    let evidenciaId;

    // Setup: Ensure users exist (assuming seeded DB)
    beforeAll(async () => {
        // Login Comercial
        const resComercial = await request(app)
            .post('/api/v2/auth/login')
            .send({ email: 'comercial@tigo.com.co', password: '123456' }); // Assuming default seed
        if (resComercial.statusCode !== 200) console.error('Comercial Login Failed:', resComercial.body);
        comercialToken = resComercial.body.data.accessToken;
        expect(comercialToken).toBeDefined();

        // Login Productor
        const resProductor = await request(app)
            .post('/api/v2/auth/login')
            .send({ email: 'productor@tigo.com.co', password: '123456' });
        if (resProductor.statusCode !== 200) console.error('Productor Login Failed:', resProductor.body);
        productorToken = resProductor.body.data.accessToken;
        expect(productorToken).toBeDefined();

        // Login Cliente
        const resCliente = await request(app)
            .post('/api/v2/auth/login')
            .send({ email: 'cliente@tigo.com.co', password: '123456' });
        if (resCliente.statusCode !== 200) console.error('Cliente Login Failed:', resCliente.body);
        clienteToken = resCliente.body.data.accessToken;
        expect(clienteToken).toBeDefined();
    });

    afterAll(() => {
        if (fs.existsSync(mockFilePath)) {
            fs.unlinkSync(mockFilePath);
        }
    });

    test('Step 1: Comercial creates an Activity', async () => {
        const newActivity = {
            comercial_id: 1, // Assuming ID 1
            productor_id: 2, // Assuming ID 2
            proyecto_id: 1, // Assuming ID 1 (General Project)
            agencia: 'Test Agency',
            codigos: `TEST-${Date.now()}`,
            semana: '50',
            responsable_actividad: 'Test User',
            segmento: 'Test Segment',
            clase_ppto: 'Test Class',
            canal: 'Test Channel',
            ciudad: 'Test City',
            punto_venta: 'Test POS',
            direccion: 'Test Address',
            fecha: new Date().toISOString().split('T')[0],
            hora_inicio: '08:00',
            hora_fin: '10:00',
            valor_total: 100000,
            responsable_canal: 'Test Resp',
            celular_responsable: '1234567890',
            recursos_agencia: 'Test Resource'
        };

        const res = await request(app)
            .post('/api/v2/actividades')
            .set('Authorization', `Bearer ${comercialToken}`)
            .send(newActivity);

        expect(res.statusCode).toEqual(201);
        expect(res.body.data).toHaveProperty('id');
        actividadId = res.body.data.id;

        // Verify auto-created budget
        const budgetRes = await request(app)
            .get(`/api/v2/presupuestos/actividad/${actividadId}`)
            .set('Authorization', `Bearer ${comercialToken}`);

        expect(budgetRes.statusCode).toEqual(200);
        expect(budgetRes.body.data).toBeDefined();

        // Add a budget item for evidence upload
        const budgetId = budgetRes.body.data.id;
        const itemRes = await request(app)
            .post(`/api/v2/presupuestos/${budgetId}/items`)
            .set('Authorization', `Bearer ${comercialToken}`)
            .send({
                item: 'Test Item',
                cantidad: 1,
                costo_unitario_cop: 10000,
                subtotal_cop: 10000,
                impuesto_cop: 0,
                comentario: 'Test Item Comment'
            });

        expect(itemRes.statusCode).toEqual(201);
        presupuestoItemId = itemRes.body.data.id;
    });

    test('Step 2: Productor uploads Evidence', async () => {
        const res = await request(app)
            .post('/api/v2/evidencias')
            .set('Authorization', `Bearer ${productorToken}`)
            .field('presupuesto_item_id', presupuestoItemId)
            .field('tipo', 'image')
            .attach('evidencia', mockFilePath);

        if (res.statusCode !== 201) console.error('Upload Failed:', res.body);
        expect(res.statusCode).toEqual(201);
        // createEvidencia returns a single object in data, not an array
        expect(res.body.data).toHaveProperty('id');
        evidenciaId = res.body.data.id;
    });

    test('Step 3: Cliente approves Evidence', async () => {
        const res = await request(app)
            .put(`/api/v2/evidencias/${evidenciaId}/status`)
            .set('Authorization', `Bearer ${clienteToken}`)
            .send({ status: 'aprobado' });

        expect(res.statusCode).toEqual(200);
        expect(res.body.data.status).toEqual('aprobado');
    });

    test('Step 4: Verify Activity Finalization', async () => {
        // Fetch activity again to check status
        const res = await request(app)
            .get(`/api/v2/actividades/${actividadId}`)
            .set('Authorization', `Bearer ${comercialToken}`);

        expect(res.statusCode).toEqual(200);
        expect(res.body.data.status).toEqual('Finalizada');
        expect(res.body.data.sub_status).toEqual('Completado');
    });
});
