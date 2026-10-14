const express = require("express");
const { myNotifications, unreadCount, markAsRead } = require("../controllers/notificationController");
const { protect } = require("../middleware/authMiddleware");

const router = express.Router();

router.get("/mine", protect, myNotifications);
router.get("/unread-count", protect, unreadCount);
router.put("/:id/read", protect, markAsRead);

module.exports = router;
