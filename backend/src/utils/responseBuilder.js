const buildResponse = (res, statusCode, success, message, data = null) => {
  return res.status(statusCode).json({
    success,
    message,
    data,
  });
};

const successResponse = (res, message = 'Success', data = null, statusCode = 200) => {
  return buildResponse(res, statusCode, true, message, data);
};

const errorResponse = (res, message = 'Error', data = null, statusCode = 500) => {
  return buildResponse(res, statusCode, false, message, data);
};

module.exports = {
  successResponse,
  errorResponse,
};
