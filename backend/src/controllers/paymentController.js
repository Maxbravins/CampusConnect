const Payment = require("../models/Payment");
const Request = require("../models/Request");
const User = require("../models/User");
const Notification = require("../models/Notification");
const { initiateStkPush } = require("../services/mpesaService");
const { sendPaymentEmail } = require("../services/emailService");

// POST /api/payments/initiate — student pays for a request
async function initiatePayment(req, res, next) {
  try {
    const { requestId, phoneNumber } = req.body;

    const request = await Request.findById(requestId).populate("service", "name fee");
    if (!request) return res.status(404).json({ message: "Request not found" });
      if (request.student.toString() !== req.user.id.toString()) {
        return res.status(403).json({
          message: "You can only pay for your own request",
        });
      }

    const payment = await Payment.create({
      request: request._id,
      student: req.user.id,
      amount: request.service.fee,
      phoneNumber,
      status: "Pending",
    });

    const stkResponse = await initiateStkPush({
      phoneNumber,
      amount: request.service.fee,
      accountReference: request.requestNumber,
      description: `Payment for ${request.service.name}`,
    });

    payment.transactionReference = stkResponse.CheckoutRequestID;
    await payment.save();

    res.status(201).json({ payment, stkResponse });
  } catch (err) {
    next(err);
  }
}

// POST /api/payments/callback — Daraja calls this after the STK push completes
async function mpesaCallback(req, res, next) {
  try {
    const callback = req.body?.Body?.stkCallback;
    if (!callback) return res.status(400).json({ message: "Invalid callback payload" });

    const payment = await Payment.findOne({ transactionReference: callback.CheckoutRequestID });
    if (!payment) return res.status(404).json({ message: "Payment not found" });

    const success = callback.ResultCode === 0;
    payment.status = success ? "Success" : "Failed";
    await payment.save();

    if (success) {
      await Request.findByIdAndUpdate(payment.request, { status: "Paid" });
      const student = await User.findById(payment.student);

      const populatedPayment = await Payment.findById(payment._id).populate({
        path: "request",
        populate: { path: "service", select: "name" },
      });

      if (student && populatedPayment.request) {
        sendPaymentEmail(student.email, {
          serviceName: populatedPayment.request.service.name,
          requestNumber: populatedPayment.request.requestNumber,
          amount: payment.amount,
          transactionReference: payment.transactionReference,
          phoneNumber: payment.phoneNumber,
          date: new Date().toLocaleString("en-KE", { timeZone: "Africa/Nairobi" }),
        });

        await Notification.create({
          user: student._id,
          title: "Payment Received",
          message: `Your payment of KES ${payment.amount} was successful.`,
        });
      }
    }

    // Daraja expects a 200 acknowledgement
    res.json({ ResultCode: 0, ResultDesc: "Received" });
  } catch (err) {
    next(err);
  }
}

// GET /api/payments/mine — student payment history
async function myPayments(req, res, next) {
  try {
    const payments = await Payment.find({ student: req.user.id })
      .populate({ path: "request", populate: { path: "service", select: "name" } })
      .sort({ createdAt: -1 });
    res.json(payments);
  } catch (err) {
    next(err);
  }
}

// GET /api/payments — admin, all transactions
async function listPayments(req, res, next) {
  try {
    const filter = {};
    if (req.query.status) filter.status = req.query.status;

    const payments = await Payment.find(filter)
      .populate("student", "fullName email")
      .populate({ path: "request", populate: { path: "service", select: "name" } })
      .sort({ createdAt: -1 });
    res.json(payments);
  } catch (err) {
    next(err);
  }
}

module.exports = { initiatePayment, mpesaCallback, myPayments, listPayments };
