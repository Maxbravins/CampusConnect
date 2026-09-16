const express = require("express");
const { getDashboardStats } = require("../controllers/reportController");
const { protect, adminOnly } = require("../middleware/authMiddleware");

const router = express.Router();

router.get("/dashboard", protect, adminOnly, getDashboardStats);

module.exports = router;
