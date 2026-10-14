const mongoose = require("mongoose");

const announcementSchema = new mongoose.Schema(
  {
    title: { type: String, required: true },
    message: { type: String, required: true },
    createdBy: { type: mongoose.Schema.Types.ObjectId, ref: "User" },
  },
  { timestamps: true }
);

announcementSchema.index({ createdAt: -1, _id: -1 });

module.exports = mongoose.model("Announcement", announcementSchema);
