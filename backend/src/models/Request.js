const mongoose = require("mongoose");

const requestSchema = new mongoose.Schema(
  {
    requestNumber: { type: String, required: true, unique: true },
    student: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
    service: { type: mongoose.Schema.Types.ObjectId, ref: "Service", required: true },
    status: {
      type: String,
      enum: ["Pending", "Payment Required", "Paid", "Processing", "Completed"],
      default: "Pending",
    },
    submittedAt: { type: Date, default: Date.now },
    completedAt: { type: Date },
  },
  { timestamps: true }
);

module.exports = mongoose.model("Request", requestSchema);
