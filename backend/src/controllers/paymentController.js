const Payment = require("../models/Payment");
const Request = require("../models/Request");
const User = require("../models/User");
const Notification = require("../models/Notification");
const { initiateStkPush, queryStkPush } = require("../services/mpesaService");
const { sendPaymentEmail } = require("../services/emailService");
const { sendPushToUser } = require("../services/pushService");
const {
  normalizeKenyanPhone,
  callbackMetadata,
  callbackMatchesPayment,
  stkQueryConfirmsPayment,
} = require("../utils/paymentValidation");

// POST /api/payments/initiate — student pays for a request
async function initiatePayment(req, res, next) {
  try {
    const { requestId, phoneNumber: suppliedPhone } = req.body;
    if (!requestId || !suppliedPhone) return res.status(400).json({ message: "requestId and phoneNumber are required" });
    const phoneNumber = normalizeKenyanPhone(suppliedPhone);
    if (!phoneNumber) return res.status(400).json({ message: "Enter a valid Kenyan mobile number" });

    const request = await Request.findById(requestId).populate("service", "name fee");
    if (!request) return res.status(404).json({ message: "Request not found" });
    if (request.student.toString() !== req.user.id.toString()) {
      return res.status(403).json({ message: "You can only pay for your own request" });
    }
    if (request.status !== "Payment Required") {
      return res.status(409).json({ message: "This request is not awaiting payment" });
    }
    if (!Number.isSafeInteger(request.service.fee) || request.service.fee < 1) {
      return res.status(400).json({ message: "The service fee must be a whole number of at least KES 1" });
    }

    const claimedRequest = await Request.findOneAndUpdate(
      { _id: request._id, status: "Payment Required", paymentInProgress: { $ne: true } },
      { $set: { paymentInProgress: true } },
      { new: true }
    );
    if (!claimedRequest) return res.status(409).json({ message: "A payment is already in progress for this request" });

    let payment;
    try {
      payment = await Payment.create({
        request: request._id,
        student: req.user.id,
        amount: request.service.fee,
        phoneNumber,
        status: "Pending",
      });
    } catch (err) {
      await Request.findByIdAndUpdate(request._id, { $set: { paymentInProgress: false } });
      if (err.code === 11000) return res.status(409).json({ message: "A payment is already in progress for this request" });
      throw err;
    }

    let stkResponse;
    try {
      stkResponse = await initiateStkPush({
        phoneNumber,
        amount: request.service.fee,
        accountReference: request.requestNumber,
        description: `Payment for ${request.service.name}`,
      });
      if (String(stkResponse.ResponseCode) !== "0") {
        const err = new Error(stkResponse.ResponseDescription || "Daraja rejected the payment request");
        err.definitiveDarajaFailure = true;
        throw err;
      }
      if (!stkResponse.CheckoutRequestID || !stkResponse.MerchantRequestID) {
        throw new Error("Daraja did not return the expected payment identifiers");
      }
      payment.transactionReference = stkResponse.CheckoutRequestID;
      payment.merchantRequestId = stkResponse.MerchantRequestID;
      await payment.save();
    } catch (err) {
      // A timeout or network failure can happen after Daraja accepted the push.
      // Keep the request locked for reconciliation instead of risking a second charge.
      if (err.definitiveDarajaFailure || (err.response && err.response.status < 500)) {
        payment.status = "Failed";
        await payment.save();
        await Request.findByIdAndUpdate(request._id, { $set: { paymentInProgress: false } });
      }
      throw err;
    }

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
    if (!callback.CheckoutRequestID || !callback.MerchantRequestID ||
        callback.ResultCode === undefined || callback.ResultCode === null ||
        String(callback.ResultCode).trim() === "" || !Number.isInteger(Number(callback.ResultCode))) {
      return res.status(400).json({ message: "Incomplete payment callback" });
    }

    const payment = await Payment.findOne({ transactionReference: callback.CheckoutRequestID });
    if (!payment) return res.status(404).json({ message: "Payment not found" });
    if (!callback.MerchantRequestID || callback.MerchantRequestID !== payment.merchantRequestId) {
      return res.status(400).json({ message: "Callback identifiers did not match the initiated payment" });
    }
    if (payment.status !== "Pending") {
      return res.json({ ResultCode: 0, ResultDesc: "Already processed" });
    }

    const success = String(callback.ResultCode) === "0";
    const metadata = callbackMetadata(callback);
    if (success && !callbackMatchesPayment(callback, payment)) {
      return res.status(400).json({ message: "Payment callback details did not match the initiated payment" });
    }
    if (success) {
      const verified = await queryStkPush(payment.transactionReference);
      if (!stkQueryConfirmsPayment(verified, payment)) {
        return res.status(503).json({ message: "Daraja could not confirm this payment yet" });
      }
    }
    const claimedPayment = await Payment.findOneAndUpdate(
      { _id: payment._id, status: "Pending", merchantRequestId: callback.MerchantRequestID },
      { $set: {
        status: success ? "Success" : "Failed",
        resultCode: String(callback.ResultCode),
        ...(success ? { mpesaReceiptNumber: metadata.MpesaReceiptNumber } : {}),
      } },
      { new: true }
    );
    if (!claimedPayment) return res.json({ ResultCode: 0, ResultDesc: "Already processed" });

    if (success) {
      await Request.findByIdAndUpdate(payment.request, { $set: { status: "Paid", paymentInProgress: false } });
      const student = await User.findById(claimedPayment.student);

      const populatedPayment = await Payment.findById(claimedPayment._id).populate({
        path: "request",
        populate: { path: "service", select: "name" },
      });

      if (student && populatedPayment.request) {
        sendPaymentEmail(student.email, {
          serviceName: populatedPayment.request.service.name,
          requestNumber: populatedPayment.request.requestNumber,
          amount: claimedPayment.amount,
          transactionReference: claimedPayment.mpesaReceiptNumber,
          phoneNumber: claimedPayment.phoneNumber,
          date: new Date().toLocaleString("en-KE", { timeZone: "Africa/Nairobi" }),
        });

        await Notification.create({
          user: student._id,
          title: "Payment Received",
          message: `Your payment of KES ${claimedPayment.amount} was successful.`,
        });

        sendPushToUser(student, {
          title: "Payment Received",
          body: `Your payment of KES ${claimedPayment.amount} for ${populatedPayment.request.service.name} was successful.`,
          data: {
            type: "payment_success",
            requestId: populatedPayment.request._id.toString(),
          },
        });
      }
    }

    if (!success) {
      await Request.findByIdAndUpdate(payment.request, { $set: { paymentInProgress: false } });
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
