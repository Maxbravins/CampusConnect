const mongoose = require("mongoose");

const requestSchema = new mongoose.Schema(
  {
    requestNumber: { type: String, required: true, unique: true },
    student: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
    service: { type: mongoose.Schema.Types.ObjectId, ref: "Service", required: true },
    status: {
      type: String,
      enum: ["Pending", "Payment Required", "Paid", "Processing", "Completed", "Cancelled"],
      default: "Pending",
    },
    submittedAt: { type: Date, default: Date.now },
    completedAt: { type: Date },
    paymentInProgress: { type: Boolean, default: false, select: false },
  },
  { timestamps: true }
);

// Support student history, admin status filters, and recent-request dashboards.
requestSchema.index({ student: 1, createdAt: -1, _id: -1 });
requestSchema.index({ status: 1, createdAt: -1, _id: -1 });
requestSchema.index({ createdAt: -1, _id: -1 });

module.exports = mongoose.model("Request", requestSchema);
