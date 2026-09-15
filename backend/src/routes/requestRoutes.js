const express = require("express");
const {
  createRequest,
  myRequests,
  listRequests,
  updateStatus,
} = require("../controllers/requestController");
const { protect, adminOnly } = require("../middleware/authMiddleware");

const router = express.Router();

router.post("/", protect, createRequest);
router.get("/mine", protect, myRequests);
router.get("/", protect, adminOnly, listRequests);
router.put("/:id/status", protect, adminOnly, updateStatus);

module.exports = router;
