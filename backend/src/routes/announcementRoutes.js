const express = require("express");

const {
  createAnnouncement,
  listAnnouncements,
} = require("../controllers/announcementController");

const { protect, adminOnly } = require("../middleware/authMiddleware");

const router = express.Router();

router.get("/", protect, listAnnouncements);
router.post("/", protect, adminOnly, createAnnouncement);

module.exports = router;