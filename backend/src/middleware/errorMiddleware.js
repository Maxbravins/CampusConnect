function notFound(req, res, next) {
  res.status(404).json({ message: `Route not found: ${req.originalUrl}` });
}

function errorHandler(err, req, res, next) {
  const errorStatus = err.statusCode || err.status;
  const statusCode = Number.isInteger(errorStatus) && errorStatus >= 400 && errorStatus <= 599
    ? errorStatus
    : res.statusCode && res.statusCode !== 200 ? res.statusCode : 500;
  const isProduction = process.env.NODE_ENV === "production";
  if (statusCode >= 500) console.error("API request failed:", err);

  const response = {
    message: isProduction && statusCode >= 500 ? "Server error" : err.message || "Server error",
  };
  if (!isProduction) response.stack = err.stack;

  res.status(statusCode).json(response);
}

module.exports = { notFound, errorHandler };
