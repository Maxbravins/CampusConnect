const express = require("express");
const {
  initiatePayment,
  mpesaCallback,
  myPayments,
  listPayments,
} = require("../controllers/paymentController");
const { protect, adminOnly } = require("../middleware/authMiddleware");

const router = express.Router();

router.post("/initiate", protect, initiatePayment);
router.post("/callback", mpesaCallback); // called by Safaricom, no auth
router.get("/mine", protect, myPayments);
router.get("/", protect, adminOnly, listPayments);

module.exports = router;
