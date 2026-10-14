const Announcement = require("../models/Announcement");
const User = require("../models/User");
const { sendPushToUsers } = require("../services/pushService");
const { findPage, parsePagination } = require("../utils/pagination");

const PUSH_BODY_LIMIT = 140;

// Push the announcement to every active student who has a registered device.
async function pushAnnouncement(announcement) {
  const students = await User.find({
    role: "student",
    status: "active",
    fcmToken: { $exists: true, $ne: "" },
  }).select("fcmToken");

  const text = announcement.message || "";
  await sendPushToUsers(students, {
    title: announcement.title,
    body: text.length > PUSH_BODY_LIMIT ? `${text.slice(0, PUSH_BODY_LIMIT - 1)}…` : text,
    data: { type: "announcement", announcementId: announcement._id.toString() },
  });
}

// POST /api/announcements — admin creates an announcement
async function createAnnouncement(req, res, next) {
  try {
    const { title, message } = req.body;

    if (!title || !message) {
      return res.status(400).json({
        message: "Title and message are required",
      });
    }

    const announcement = await Announcement.create({
      title,
      message,
      createdBy: req.user.id,
    });

    // Fire and forget: the admin should not wait on (or fail because of) push delivery.
    pushAnnouncement(announcement).catch((err) => console.warn(`Announcement push failed: ${err.message}`));

    res.status(201).json(announcement);
  } catch (err) {
    next(err);
  }
}

// GET /api/announcements — students view announcements
async function listAnnouncements(req, res, next) {
  try {
    const pagination = parsePagination(req.query);
    if (!pagination) return res.status(400).json({ message: "page and limit must be positive integers" });

    const result = await findPage({
      model: Announcement,
      populate: [["createdBy", "fullName"]],
      ...pagination,
    });
    res.json(result.items);
  } catch (err) {
    next(err);
  }
}

module.exports = {
  createAnnouncement,
  listAnnouncements,
};
