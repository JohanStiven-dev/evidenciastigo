const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const { protect } = require('../middleware/authMiddleware');
const validate = require('../middleware/validationMiddleware');
const { registerValidation, loginValidation } = require('../utils/authValidation');

router.post('/register', registerValidation, validate, authController.registerUser); // For initial setup/testing
/**
 * @swagger
 * tags:
 *   name: Auth
 *   description: Autenticación de usuarios
 */

/**
 * @swagger
 * /auth/login:
 *   post:
 *     summary: Iniciar sesión de usuario
 *     tags: [Auth]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - email
 *               - password
 *             properties:
 *               email:
 *                 type: string
 *                 format: email
 *                 example: admin.tester@example.com
 *               password:
 *                 type: string
 *                 format: password
 *                 example: password12345
 *     responses:
 *       200:
 *         description: Inicio de sesión exitoso
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 message:
 *                   type: string
 *                   example: Logged in successfully
 *                 data:
 *                   type: object
 *                   properties:
 *                     id:
 *                       type: integer
 *                       example: 1
 *                     nombre:
 *                       type: string
 *                       example: Admin Tester
 *                     email:
 *                       type: string
 *                       example: admin.tester@example.com
 *                     rol:
 *                       type: string
 *                       example: Administrador
 *                     accessToken:
 *                       type: string
 *                       example: eyJhbGciOiJIUzI1Ni...
 *                     refreshToken:
 *                       type: string
 *                       example: eyJhbGciOiJIUzI1Ni...
 *       401:
 *         description: Credenciales inválidas
 *       400:
 *         description: Datos de entrada inválidos
 */
router.post('/login', loginValidation, validate, authController.login);

/**
 * @swagger
 * /auth/refresh:
 *   post:
 *     summary: Refrescar token de acceso
 *     tags: [Auth]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - refreshToken
 *             properties:
 *               refreshToken:
 *                 type: string
 *                 example: eyJhbGciOiJIUzI1Ni...
 *     responses:
 *       200:
 *         description: Token de acceso refrescado exitosamente
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 message:
 *                   type: string
 *                   example: Access token refreshed
 *                 data:
 *                   type: object
 *                   properties:
 *                     id:
 *                       type: integer
 *                       example: 1
 *                     nombre:
 *                       type: string
 *                       example: Admin Tester
 *                     email:
 *                       type: string
 *                       example: admin.tester@example.com
 *                     rol:
 *                       type: string
 *                       example: Administrador
 *                     accessToken:
 *                       type: string
 *                       example: eyJhbGciOiJIUzI1Ni...
 *                     refreshToken:
 *                       type: string
 *                       example: eyJhbGciOiJIUzI1Ni...
 *       403:
 *         description: Token de refresco inválido o expirado
 *       401:
 *         description: No se proporcionó token de refresco
 */
router.post('/refresh', authController.refreshToken);
router.get('/profile', protect, authController.getProfile);
router.post('/logout', protect, authController.logout);

module.exports = router;