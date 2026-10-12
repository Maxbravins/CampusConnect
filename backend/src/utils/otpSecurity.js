const crypto = require("crypto");

function hashOtp(otp, secret) {
  if (!secret) throw new Error("A secret is required to hash a password reset OTP");
  return crypto.createHmac("sha256", secret).update(otp).digest("hex");
}

function otpMatches(storedHash, otp, secret) {
  if (!storedHash || !/^\d{6}$/.test(otp || "")) return false;
  const suppliedHash = Buffer.from(hashOtp(otp, secret), "hex");
  const expectedHash = Buffer.from(storedHash, "hex");
  return expectedHash.length === suppliedHash.length && crypto.timingSafeEqual(expectedHash, suppliedHash);
}

module.exports = { hashOtp, otpMatches };
