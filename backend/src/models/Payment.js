const mongoose = require("mongoose");

const paymentSchema = new mongoose.Schema(
  {
    request: { type: mongoose.Schema.Types.ObjectId, ref: "Request", required: true },
    student: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
    amount: { type: Number, required: true },
    phoneNumber: { type: String, required: true },
    transactionReference: { type: String, trim: true },
    status: { type: String, enum: ["Pending", "Success", "Failed"], default: "Pending" },
  },
  { timestamps: true }
);

module.exports = mongoose.model("Payment", paymentSchema);
