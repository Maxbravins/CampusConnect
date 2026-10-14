const Notification = require("../models/Notification");
const { findPage, parsePagination } = require("../utils/pagination");

// GET /api/notifications/mine
async function myNotifications(req, res, next) {
  try {
    const pagination = parsePagination(req.query);
    if (!pagination) return res.status(400).json({ message: "page and limit must be positive integers" });

    const result = await findPage({
      model: Notification,
      filter: { user: req.user.id },
      ...pagination,
    });
    res.json(result.items);
  } catch (err) {
    next(err);
  }
}

async function unreadCount(req, res, next) {
  try {
    const count = await Notification.countDocuments({ user: req.user.id, read: false });
    res.json({ count });
  } catch (err) {
    next(err);
  }
}

// PUT /api/notifications/:id/read
async function markAsRead(req, res, next) {
  try {
    const notification = await Notification.findOneAndUpdate(
      { _id: req.params.id, user: req.user.id },
      { read: true },
      { new: true }
    );
    if (!notification) return res.status(404).json({ message: "Notification not found" });
    res.json(notification);
  } catch (err) {
    next(err);
  }
}

module.exports = { myNotifications, unreadCount, markAsRead };
