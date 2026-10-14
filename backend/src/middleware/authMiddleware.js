const jwt = require("jsonwebtoken");
const User = require("../models/User");

async function protect(req, res, next) {
  const header = req.headers.authorization;
  if (!header || !header.startsWith("Bearer ")) {
    return res.status(401).json({ message: "Not authorized, no token" });
  }

  let decoded;
  try {
    const token = header.split(" ")[1];
    decoded = jwt.verify(token, process.env.JWT_SECRET);
  } catch (err) {
    return res.status(401).json({ message: "Not authorized, invalid token" });
  }

  try {
    const user = await User.findById(decoded.id).select("role status");
    if (!user || user.status === "inactive") {
      return res.status(401).json({ message: "Not authorized, account is inactive or no longer exists" });
    }

    // Use the current database role so role changes also take effect immediately.
    req.user = { ...decoded, role: user.role };
    return next();
  } catch (err) {
    return next(err);
  }
}

function adminOnly(req, res, next) {
  if (req.user?.role !== "admin") {
    return res.status(403).json({ message: "Admin access required" });
  }
  next();
}

module.exports = { protect, adminOnly };
