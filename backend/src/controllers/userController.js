const User = require("../models/User");
const { findPage, parsePagination } = require("../utils/pagination");
const { escapeRegexLiteral } = require("../utils/search");

// GET /api/users/me — any logged-in user views their own profile
async function getMe(req, res, next) {
  try {
    const user = await User.findById(req.user.id).select("-password");
    if (!user) return res.status(404).json({ message: "User not found" });
    res.json(user);
  } catch (err) {
    next(err);
  }
}

// PUT /api/users/me — any logged-in user updates their own name/phone
async function updateMe(req, res, next) {
  try {
    const { fullName, phone } = req.body;
    const update = {};
    if (fullName !== undefined) update.fullName = fullName;
    if (phone !== undefined) update.phone = phone;

    const user = await User.findByIdAndUpdate(req.user.id, update, { new: true }).select(
      "-password"
    );
    if (!user) return res.status(404).json({ message: "User not found" });
    res.json(user);
  } catch (err) {
    next(err);
  }
}

// GET /api/users — admin: list/search students
async function listUsers(req, res, next) {
  try {
    const { search, role } = req.query;
    const pagination = parsePagination(req.query);
    if (!pagination) return res.status(400).json({ message: "page and limit must be positive integers" });
    if (search !== undefined && (typeof search !== "string" || search.length > 100)) {
      return res.status(400).json({ message: "search must be a string of 100 characters or fewer" });
    }
    if (role !== undefined && !["student", "admin"].includes(role)) {
      return res.status(400).json({ message: "role must be student or admin" });
    }

    const filter = {};
    if (role) filter.role = role;
    if (search?.trim()) {
      const literalSearch = escapeRegexLiteral(search.trim());
      const searchPattern = new RegExp(literalSearch, "i");
      filter.$or = [
        { fullName: searchPattern },
        { email: searchPattern },
        { studentId: searchPattern },
      ];
    }

    const result = await findPage({ model: User, filter, select: "-password", ...pagination });
    res.json(result);
  } catch (err) {
    next(err);
  }
}

// GET /api/users/:id — admin: view a student's details
async function getUser(req, res, next) {
  try {
    const user = await User.findById(req.params.id).select("-password");
    if (!user) return res.status(404).json({ message: "User not found" });
    res.json(user);
  } catch (err) {
    next(err);
  }
}

// PUT /api/users/:id/status — admin: activate/deactivate an account
async function updateUserStatus(req, res, next) {
  try {
    const { status } = req.body;
    const user = await User.findByIdAndUpdate(req.params.id, { status }, { new: true }).select(
      "-password"
    );
    if (!user) return res.status(404).json({ message: "User not found" });
    res.json(user);
  } catch (err) {
    next(err);
  }
}

// PUT /api/users/fcm-token — logged-in user registers/updates their device's push token
async function updateFcmToken(req, res, next) {
  try {
    const { fcmToken } = req.body;
    if (!fcmToken) return res.status(400).json({ message: "fcmToken is required" });

    // A device token belongs to one account. If someone else logged in on this
    // device before, stop sending their notifications to it.
    await User.updateMany({ fcmToken, _id: { $ne: req.user.id } }, { $unset: { fcmToken: 1 } });
    await User.findByIdAndUpdate(req.user.id, { fcmToken });
    res.json({ message: "Token registered" });
  } catch (err) {
    next(err);
  }
}

// DELETE /api/users/fcm-token — called on logout so this device stops receiving the user's pushes
async function clearFcmToken(req, res, next) {
  try {
    await User.findByIdAndUpdate(req.user.id, { $unset: { fcmToken: 1 } });
    res.json({ message: "Token removed" });
  } catch (err) {
    next(err);
  }
}

module.exports = { getMe, updateMe, listUsers, getUser, updateUserStatus, updateFcmToken, clearFcmToken };
