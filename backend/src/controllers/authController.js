const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const crypto = require("crypto");
const User = require("../models/User");
const { hashOtp, otpMatches } = require("../utils/otpSecurity");
const { sendRegistrationEmail, sendPasswordResetOtp } = require("../services/emailService");

function generateToken(user) {
  return jwt.sign(
    { id: user._id, role: user.role },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_EXPIRES_IN || "7d" }
  );
}

async function findOtpUser(email) {
  return User.findOne({ email: email.trim().toLowerCase() })
    .select("+resetPasswordOtp +resetPasswordOtpAttempts");
}

async function validOtp(user, otp) {
  if (!user || !user.resetPasswordOtp || !user.resetPasswordOtpExpires ||
      user.resetPasswordOtpExpires < new Date() || user.resetPasswordOtpAttempts >= 5) {
    return false;
  }
  if (otpMatches(user.resetPasswordOtp, otp, process.env.JWT_SECRET)) return true;
  user.resetPasswordOtpAttempts = Number(user.resetPasswordOtpAttempts || 0) + 1;
  await user.save();
  return false;
}

// POST /api/auth/register
async function register(req, res, next) {
  try {
    const { fullName, studentId, email, phone, password } = req.body;

    if (!fullName || !email || !phone || !password) {
      return res.status(400).json({ message: "Missing required fields" });
    }

    if (password.length < 8) {
      return res.status(400).json({ message: "Password must be at least 8 characters" });
    }

    const normalizedEmail = email.trim().toLowerCase();
    const existing = await User.findOne({ email: normalizedEmail });
    if (existing) {
      return res.status(409).json({ message: "Email already registered" });
    }

    const hashed = await bcrypt.hash(password, 10);
    const user = await User.create({
      fullName,
      studentId,
      email: normalizedEmail,
      phone,
      password: hashed,
    });

    sendRegistrationEmail(user.email, user.fullName);

    res.status(201).json({
      token: generateToken(user),
      user: { id: user._id, fullName: user.fullName, email: user.email, role: user.role },
    });
  } catch (err) {
    next(err);
  }
}

// POST /api/auth/login
async function login(req, res, next) {
  try {
    const { email, password } = req.body;
    if (!email || !password) return res.status(400).json({ message: "Email and password are required" });
    const user = await User.findOne({ email: email.trim().toLowerCase() });

    if (!user || !(await bcrypt.compare(password, user.password))) {
      return res.status(401).json({ message: "Invalid email or password" });
    }

    if (user.status === "inactive") {
      return res.status(403).json({ message: "Account is inactive" });
    }

    res.json({
      token: generateToken(user),
      user: { id: user._id, fullName: user.fullName, email: user.email, role: user.role },
    });
  } catch (err) {
    next(err);
  }
}

// POST /api/auth/forgot-password
async function forgotPassword(req, res, next) {
  try {
    const { email } = req.body;

    if (!email) {
      return res.status(400).json({
        message: "Email is required",
      });
    }

    const user = await User.findOne({ email: email.trim().toLowerCase() });

    // Do not reveal whether an email exists.
    if (!user) {
      return res.json({
        message: "If the email exists, a password reset OTP has been sent.",
      });
    }

    const otp = crypto.randomInt(100000, 1000000).toString();

    user.resetPasswordOtp = hashOtp(otp, process.env.JWT_SECRET);
    user.resetPasswordOtpExpires = new Date(Date.now() + 10 * 60 * 1000);
    user.resetPasswordOtpAttempts = 0;

    await user.save();

    sendPasswordResetOtp(user.email, otp);

    res.json({
      message: "If the email exists, a password reset OTP has been sent.",
    });
  } catch (err) {
    next(err);
  }
}

// POST /api/auth/verify-reset-otp
async function verifyResetOtp(req, res, next) {
  try {
    const { email, otp } = req.body;

    if (!email || !otp) {
      return res.status(400).json({
        message: "Email and OTP are required",
      });
    }

    const user = await findOtpUser(email);
    if (!(await validOtp(user, otp))) {
      return res.status(400).json({
        message: "Invalid or expired OTP",
      });
    }

    res.json({
      message: "OTP verified successfully",
    });
  } catch (err) {
    next(err);
  }
}

// POST /api/auth/reset-password
async function resetPassword(req, res, next) {
  try {
    const { email, otp, newPassword } = req.body;

    if (!email || !otp || !newPassword) {
      return res.status(400).json({
        message: "Email, OTP, and new password are required",
      });
    }

    if (newPassword.length < 8) {
      return res.status(400).json({
        message: "Password must be at least 8 characters",
      });
    }

    const user = await findOtpUser(email);
    if (!(await validOtp(user, otp))) {
      return res.status(400).json({
        message: "Invalid or expired OTP",
      });
    }

    user.password = await bcrypt.hash(newPassword, 10);

    user.resetPasswordOtp = undefined;
    user.resetPasswordOtpExpires = undefined;
    user.resetPasswordOtpAttempts = 0;

    await user.save();

    res.json({
      message: "Password reset successfully",
    });
  } catch (err) {
    next(err);
  }
}

module.exports = { register, login, forgotPassword, verifyResetOtp, resetPassword, };
