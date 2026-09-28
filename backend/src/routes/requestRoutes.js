const express = require("express");
const {
  createRequest,
  myRequests,
  listRequests,
  updateStatus,
  cancelRequest,
} = require("../controllers/requestController");
const { protect, adminOnly } = require("../middleware/authMiddleware");

const router = express.Router();

router.post("/", protect, createRequest);
router.get("/mine", protect, myRequests);
router.get("/", protect, adminOnly, listRequests);
router.put("/:id/status", protect, adminOnly, updateStatus);
router.patch("/:id/cancel", protect, cancelRequest);

module.exports = router;
