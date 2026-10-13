const mongoose = require("mongoose");

const paymentSchema = new mongoose.Schema(
  {
    request: { type: mongoose.Schema.Types.ObjectId, ref: "Request", required: true },
    student: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
    amount: { type: Number, required: true },
    phoneNumber: { type: String, required: true },
    transactionReference: { type: String, trim: true },
    merchantRequestId: { type: String, trim: true },
    mpesaReceiptNumber: { type: String, trim: true },
    resultCode: { type: String, trim: true },
    status: { type: String, enum: ["Pending", "Success", "Failed"], default: "Pending" },
    // Set by the reconciliation job when a payment could not be confirmed either way.
    needsReview: { type: Boolean, default: false },
    reconciledAt: { type: Date },
    reconcileNote: { type: String, trim: true },
  },
  { timestamps: true }
);

// Prevent two concurrent STK pushes for the same request.
paymentSchema.index({ request: 1 }, { unique: true, partialFilterExpression: { status: "Pending" } });

module.exports = mongoose.model("Payment", paymentSchema);
