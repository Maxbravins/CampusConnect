const User = require("../models/User");

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
    const filter = {};
    if (role) filter.role = role;
    if (search) {
      filter.$or = [
        { fullName: new RegExp(search, "i") },
        { email: new RegExp(search, "i") },
        { studentId: new RegExp(search, "i") },
      ];
    }

    const users = await User.find(filter).select("-password").sort({ createdAt: -1 });
    res.json(users);
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

module.exports = { getMe, updateMe, listUsers, getUser, updateUserStatus };
