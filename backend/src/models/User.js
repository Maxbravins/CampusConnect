const mongoose = require("mongoose");

const userSchema = new mongoose.Schema(
  {
    fullName: { type: String, required: true, trim: true },
    studentId: { type: String, trim: true, sparse: true, unique: true },
    email: { type: String, required: true, unique: true, lowercase: true, trim: true },
    phone: { type: String, required: true, trim: true },
    password: { type: String, required: true },
    role: { type: String, enum: ["student", "admin"], default: "student" },
    status: { type: String, enum: ["active", "inactive"], default: "active" },
    resetPasswordOtp: { type: String, select: false },
    resetPasswordOtpExpires: { type: Date },
    resetPasswordOtpAttempts: { type: Number, default: 0, select: false },
    fcmToken: { type: String },
  },
  { timestamps: true }
);

// Supports role-filtered admin pages and the dashboard's student count.
userSchema.index({ role: 1, createdAt: -1, _id: -1 });

module.exports = mongoose.model("User", userSchema);
