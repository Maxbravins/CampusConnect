const Announcement = require("../models/Announcement");

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

    res.status(201).json(announcement);
  } catch (err) {
    next(err);
  }
}

// GET /api/announcements — students view announcements
async function listAnnouncements(req, res, next) {
  try {
    const announcements = await Announcement.find()
      .populate("createdBy", "fullName")
      .sort({ createdAt: -1 });

    res.json(announcements);
  } catch (err) {
    next(err);
  }
}

module.exports = {
  createAnnouncement,
  listAnnouncements,
};