const express = require("express");
const { rateLimit } = require("express-rate-limit");

const {
  register,
  login,
  forgotPassword,
  verifyResetOtp,
  resetPassword,
} = require("../controllers/authController");

const router = express.Router();

const createAuthLimiter = (limit, windowMs, message) => rateLimit({
  windowMs,
  limit,
  standardHeaders: "draft-8",
  legacyHeaders: false,
  message: { message },
});

const registrationLimiter = createAuthLimiter(
  5,
  15 * 60 * 1000,
  "Too many registration attempts. Please try again in 15 minutes."
);
const loginLimiter = createAuthLimiter(
  10,
  15 * 60 * 1000,
  "Too many login attempts. Please try again in 15 minutes."
);
const forgotPasswordLimiter = createAuthLimiter(
  3,
  60 * 60 * 1000,
  "Too many password reset requests. Please try again in an hour."
);
const resetOtpLimiter = createAuthLimiter(
  5,
  15 * 60 * 1000,
  "Too many OTP attempts. Please request a new reset code later."
);
const resetPasswordLimiter = createAuthLimiter(
  5,
  15 * 60 * 1000,
  "Too many password reset attempts. Please try again in 15 minutes."
);

router.post("/register", registrationLimiter, register);
router.post("/login", loginLimiter, login);
router.post("/forgot-password", forgotPasswordLimiter, forgotPassword);
router.post("/verify-reset-otp", resetOtpLimiter, verifyResetOtp);
router.post("/reset-password", resetPasswordLimiter, resetPassword);

module.exports = router;
