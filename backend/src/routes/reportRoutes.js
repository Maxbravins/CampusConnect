const express = require("express");
const {
  getDashboardStats,
  exportRequestsCsv,
  exportPaymentsCsv,
} = require("../controllers/reportController");
const { protect, adminOnly } = require("../middleware/authMiddleware");

const router = express.Router();

router.get("/dashboard", protect, adminOnly, getDashboardStats);
router.get("/export/requests", protect, adminOnly, exportRequestsCsv);
router.get("/export/payments", protect, adminOnly, exportPaymentsCsv);

module.exports = router;
