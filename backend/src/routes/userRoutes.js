const express = require("express");
const {
  getMe,
  updateMe,
  listUsers,
  getUser,
  updateUserStatus,
} = require("../controllers/userController");
const { protect, adminOnly } = require("../middleware/authMiddleware");

const router = express.Router();

// IMPORTANT: /me routes must come before /:id, or Express will treat
// "me" as an :id value and route it to the wrong handler.
router.get("/me", protect, getMe);
router.put("/me", protect, updateMe);

router.get("/", protect, adminOnly, listUsers);
router.get("/:id", protect, adminOnly, getUser);
router.put("/:id/status", protect, adminOnly, updateUserStatus);

module.exports = router;
