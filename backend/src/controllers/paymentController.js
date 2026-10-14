const Payment = require("../models/Payment");
const Request = require("../models/Request");
const { initiateStkPush, queryStkPush } = require("../services/mpesaService");
const { fulfillSuccessfulPayment, notifyPaymentFailed } = require("../services/paymentFulfillment");
const reconciler = require("../services/paymentReconciler");
const {
  normalizeKenyanPhone,
  callbackMetadata,
  callbackMatchesPayment,
  stkQueryConfirmsPayment,
} = require("../utils/paymentValidation");
const { findPage, parsePagination } = require("../utils/pagination");

// POST /api/payments/initiate — student pays for a request
async function initiatePayment(req, res, next) {
  try {
    const { requestId, phoneNumber: suppliedPhone } = req.body;
    if (!requestId || !suppliedPhone) return res.status(400).json({ message: "requestId and phoneNumber are required" });
    const phoneNumber = normalizeKenyanPhone(suppliedPhone);
    if (!phoneNumber) return res.status(400).json({ message: "Enter a valid Kenyan mobile number" });

    // Verify ownership before reconciling, because reconciliation contacts Daraja
    // and may update payment and request state.
    const requestOwner = await Request.findById(requestId).select("student");
    if (!requestOwner) return res.status(404).json({ message: "Request not found" });
    if (requestOwner.student.toString() !== req.user.id.toString()) {
      return res.status(403).json({ message: "You can only pay for your own request" });
    }

    // If an earlier attempt is stuck, settle it with Daraja first so the student isn't locked out.
    const earlier = await Payment.findOne({ request: requestId, status: "Pending" });
    if (earlier) await reconciler.reconcilePayment(earlier).catch(() => {});

    // Re-read because reconciliation may have changed the request's payment status.
    const request = await Request.findById(requestId).populate("service", "name fee");
    if (!request) return res.status(404).json({ message: "Request not found" });
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
      // The reconciler may have confirmed this payment by query, which has no receipt number.
      if (payment.status === "Success" && !payment.mpesaReceiptNumber &&
          String(callback.ResultCode) === "0" && callbackMatchesPayment(callback, payment)) {
        await Payment.updateOne(
          { _id: payment._id, mpesaReceiptNumber: { $in: [null, ""] } },
          { $set: { mpesaReceiptNumber: callbackMetadata(callback).MpesaReceiptNumber } }
        );
      }
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

    if (success) await fulfillSuccessfulPayment(claimedPayment);

    if (!success) {
      await Request.findByIdAndUpdate(payment.request, { $set: { paymentInProgress: false } });
      await notifyPaymentFailed(claimedPayment);
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
    const pagination = parsePagination(req.query);
    if (!pagination) return res.status(400).json({ message: "page and limit must be positive integers" });

    const result = await findPage({
      model: Payment,
      filter: { student: req.user.id },
      populate: [[{ path: "request", populate: { path: "service", select: "name" } }]],
      ...pagination,
    });
    res.json(result.items);
  } catch (err) {
    next(err);
  }
}

// GET /api/payments — admin, all transactions
async function listPayments(req, res, next) {
  try {
    const pagination = parsePagination(req.query);
    if (!pagination) return res.status(400).json({ message: "page and limit must be positive integers" });
    if (req.query.status !== undefined && !["Pending", "Success", "Failed"].includes(req.query.status)) {
      return res.status(400).json({ message: "Invalid payment status filter" });
    }
    if (req.query.needsReview !== undefined && !["true", "false"].includes(req.query.needsReview)) {
      return res.status(400).json({ message: "needsReview must be true or false" });
    }

    const filter = {};
    if (req.query.status) filter.status = req.query.status;
    if (req.query.needsReview === "true") filter.needsReview = true;

    const result = await findPage({
      model: Payment,
      filter,
      populate: [["student", "fullName email"], [{ path: "request", populate: { path: "service", select: "name" } }]],
      ...pagination,
    });
    res.json(result);
  } catch (err) {
    next(err);
  }
}

// POST /api/payments/reconcile — admin, settle stuck payments now instead of waiting for the job
async function reconcilePayments(req, res, next) {
  try {
    const results = await reconciler.reconcileStalePayments();
    const summary = results.reduce((acc, r) => ({ ...acc, [r.action]: (acc[r.action] || 0) + 1 }), {});
    res.json({ checked: results.length, summary, results });
  } catch (err) {
    next(err);
  }
}

module.exports = { initiatePayment, mpesaCallback, myPayments, listPayments, reconcilePayments };
