const express = require("express");
const { myNotifications, markAsRead } = require("../controllers/notificationController");
const { protect } = require("../middleware/authMiddleware");

const router = express.Router();

router.get("/mine", protect, myNotifications);
router.put("/:id/read", protect, markAsRead);

module.exports = router;
