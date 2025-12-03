const { body } = require('express-validator');
const { validateEmail } = require('./validators');

const registerValidation = [
  body('nombre').notEmpty().withMessage('Name is required'),
  body('email').isEmail().withMessage('Please enter a valid email').custom(value => {
    if (!validateEmail(value)) {
      throw new Error('Email format is invalid');
    }
    return true;
  }),
  body('password').isLength({ min: 8 }).withMessage('Password must be at least 8 characters long'),
  body('rol').isIn(['Comercial', 'Productor', 'Cliente']).withMessage('Invalid role'),
];

const loginValidation = [
  body('email').isEmail().withMessage('Please enter a valid email'),
  body('password').notEmpty().withMessage('Password is required'),
];

module.exports = {
  registerValidation,
  loginValidation,
};
