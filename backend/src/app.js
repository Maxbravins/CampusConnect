const express = require("express");
const cors = require("cors");
const morgan = require("morgan");

const authRoutes = require("./routes/authRoutes");
const userRoutes = require("./routes/userRoutes");
const serviceRoutes = require("./routes/serviceRoutes");
const requestRoutes = require("./routes/requestRoutes");
const paymentRoutes = require("./routes/paymentRoutes");
const notificationRoutes = require("./routes/notificationRoutes");
const { notFound, errorHandler } = require("./middleware/errorMiddleware");
const reportRoutes = require("./routes/reportRoutes");
const announcementRoutes = require("./routes/announcementRoutes");

const app = express();

const trustProxyHops = process.env.TRUST_PROXY_HOPS;
if (trustProxyHops !== undefined && trustProxyHops !== "") {
  if (!/^\d+$/.test(trustProxyHops) || !Number.isSafeInteger(Number(trustProxyHops)) || Number(trustProxyHops) < 1) {
    throw new Error("TRUST_PROXY_HOPS must be a positive integer when set.");
  }
  app.set("trust proxy", Number(trustProxyHops));
}

const allowedOrigins = (process.env.CORS_ORIGIN || "http://localhost:3000")
  .split(",")
  .map((origin) => origin.trim())
  .filter(Boolean);
app.use(cors({ origin(origin, callback) {
  if (!origin) return callback(null, true);
  if (process.env.NODE_ENV !== "production") {
    try {
      const hostname = new URL(origin).hostname;
      if (hostname === "localhost" || hostname === "127.0.0.1") return callback(null, true);
    } catch (_) {
      return callback(null, false);
    }
  }
  return callback(null, allowedOrigins.includes(origin));
} }));
app.use(express.json());
app.use(morgan("dev"));

app.get("/api/health", (req, res) => res.json({ status: "ok" }));

app.use("/api/auth", authRoutes);
app.use("/api/users", userRoutes);
app.use("/api/services", serviceRoutes);
app.use("/api/requests", requestRoutes);
app.use("/api/payments", paymentRoutes);
app.use("/api/notifications", notificationRoutes);
app.use("/api/reports", reportRoutes);
app.use("/api/announcements", announcementRoutes);

app.use(notFound);
app.use(errorHandler);

module.exports = app;
