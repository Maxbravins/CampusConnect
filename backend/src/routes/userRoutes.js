const express = require("express");
const { listUsers, getUser, updateUserStatus } = require("../controllers/userController");
const { protect, adminOnly } = require("../middleware/authMiddleware");

const router = express.Router();

router.get("/", protect, adminOnly, listUsers);
router.get("/:id", protect, adminOnly, getUser);
router.put("/:id/status", protect, adminOnly, updateUserStatus);

module.exports = router;
