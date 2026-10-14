// Everything that must happen once a payment is confirmed successful.
// Shared by the M-Pesa callback handler and the reconciliation job.
const Payment = require("../models/Payment");
const Request = require("../models/Request");
const User = require("../models/User");
const Notification = require("../models/Notification");
const { sendPaymentEmail } = require("./emailService");
const { sendPushToUser } = require("./pushService");

async function fulfillSuccessfulPayment(payment) {
  await Request.findByIdAndUpdate(payment.request, { $set: { status: "Paid", paymentInProgress: false } });
  const student = await User.findById(payment.student);

  const populated = await Payment.findById(payment._id).populate({
    path: "request",
    populate: { path: "service", select: "name" },
  });

  if (student && populated?.request) {
    sendPaymentEmail(student.email, {
      serviceName: populated.request.service.name,
      requestNumber: populated.request.requestNumber,
      amount: payment.amount,
      transactionReference: payment.mpesaReceiptNumber || payment.transactionReference,
      phoneNumber: payment.phoneNumber,
      date: new Date().toLocaleString("en-KE", { timeZone: "Africa/Nairobi" }),
    });

    await Notification.create({
      user: student._id,
      title: "Payment Received",
      message: `Your payment of KES ${payment.amount} was successful.`,
    });

    sendPushToUser(student, {
      title: "Payment Received",
      body: `Your payment of KES ${payment.amount} for ${populated.request.service.name} was successful.`,
      data: {
        type: "payment_success",
        requestId: populated.request._id.toString(),
      },
    });
  }
}

// Tells the student a payment did not go through, so they know they can retry.
// Never throws: a notification problem must not break callback handling or reconciliation.
async function notifyPaymentFailed(payment) {
  try {
    const student = await User.findById(payment.student);
    if (!student) return;

    const message = `Your M-Pesa payment of KES ${payment.amount} was not completed. You can try again from My Requests.`;
    await Notification.create({ user: student._id, title: "Payment Not Completed", message });
    sendPushToUser(student, {
      title: "Payment Not Completed",
      body: message,
      data: { type: "payment_failed", requestId: String(payment.request) },
    });
  } catch (err) {
    console.warn(`Could not send payment-failed notification: ${err.message}`);
  }
}

module.exports = { fulfillSuccessfulPayment, notifyPaymentFailed };
