const swaggerJsdoc = require('swagger-jsdoc');
const { APP_NAME, BASE_URL_API } = require('./env');

const options = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: `${APP_NAME} API Documentation`,
      version: '2.0.0',
      description: 'API RESTful para el sistema de gestión de BTL/Trade.',
    },
    servers: [
      {
        url: BASE_URL_API,
        description: 'Servidor de Desarrollo',
      },
    ],
    components: {
      securitySchemes: {
        bearerAuth: {
          type: 'http',
          scheme: 'bearer',
          bearerFormat: 'JWT',
        },
      },
    },
    security: [
      {
        bearerAuth: [],
      },
    ],
  },
  // Rutas a los archivos que contienen la documentación de la API (JSDoc)
  apis: ['./src/routes/*.js'],
};

const swaggerSpec = swaggerJsdoc(options);

module.exports = swaggerSpec;
