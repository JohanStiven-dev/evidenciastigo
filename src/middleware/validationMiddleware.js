const { validationResult } = require('express-validator');
const { ValidationError } = require('../utils/appError');

const validate = (req, res, next) => {
  const errors = validationResult(req);
  if (errors.isEmpty()) {
    return next();
  }
  const extractedErrors = [];
  errors.array().map(err => extractedErrors.push({ [err.path]: err.msg }));

  return next(new ValidationError('Validation failed', extractedErrors));
};

module.exports = validate;
