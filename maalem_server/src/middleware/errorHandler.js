// middleware/errorHandler.js

const errorHandler = (err, req, res, next) => {
  console.error(`[${new Date().toISOString()}] ${req.method} ${req.path} →`, err.message);

  const status = err.status || err.statusCode || 500;
  const message = err.isOperational ? err.message : 'Erreur serveur interne.';

  res.status(status).json({
    success: false,
    error: message,
  });
};

module.exports = errorHandler;