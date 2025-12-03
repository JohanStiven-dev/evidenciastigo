const express = require('express');
const cors = require('cors');
const errorHandler = require('./middleware/errorHandler');
const { AppError } = require('./utils/appError');
const logger = require('./config/logger');
const swaggerUi = require('swagger-ui-express');
const swaggerSpec = require('./config/swagger');
const { v4: uuidv4 } = require('uuid'); // Import uuid

const app = express();

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use('/uploads', express.static(require('path').join(__dirname, '../uploads')));

// X-Request-Id Middleware
app.use((req, res, next) => {
  const requestId = req.headers['x-request-id'] || uuidv4();
  req.requestId = requestId; // Attach to request object
  res.setHeader('X-Request-Id', requestId); // Set in response header
  next();
});

// Request logging
app.use((req, res, next) => {
  logger.info(`${req.method} ${req.originalUrl}`, { requestId: req.requestId }); // Include requestId in logs
  next();
});

// System Routes (non-versioned)
app.use('/', require('./routes/systemRoutes'));

// API v2 Routes
const apiRouter = express.Router();
apiRouter.use('/auth', require('./routes/authRoutes'));
apiRouter.use('/actividades', require('./routes/actividadRoutes'));
apiRouter.use('/actividades', require('./routes/presupuestoActivityRoutes'));
apiRouter.use('/actividades', require('./routes/evidenciaActivityRoutes'));
apiRouter.use('/presupuestos', require('./routes/presupuestoRoutes'));
apiRouter.use('/evidencias', require('./routes/evidenciaRoutes'));
apiRouter.use('/calendario', require('./routes/calendarioRoutes'));
apiRouter.use('/notificaciones', require('./routes/notificacionRoutes'));
apiRouter.use('/dashboard', require('./routes/dashboardRoutes'));
apiRouter.use('/reportes', require('./routes/reportesRoutes'));
apiRouter.use('/catalogo', require('./routes/catalogoRoutes'));
apiRouter.use('/bitacoras', require('./routes/bitacoraRoutes'));

app.use('/api/v2', apiRouter);

// Swagger UI
app.use('/docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec));
app.get('/openapi.json', (req, res) => res.json(swaggerSpec));

// Handle unfound routes
app.all('*', (req, res, next) => {
  next(new AppError(`Can't find ${req.originalUrl} on this server!`, 404));
});

// Error handling middleware
app.use(errorHandler);

module.exports = app;
