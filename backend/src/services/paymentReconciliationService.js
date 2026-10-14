// Settles payments stuck in "Pending" because a callback was lost, arrived while
// the server was down, or its Daraja verification call failed.
const {
  QUERY_AFTER_MS,
  isAbandoned,
  decideReconciliation,
  interpretStkQuery,
} = require("../utils/paymentReconciliation");

const NO_RECEIPT_NOTE =
  "Confirmed via Daraja STK query. The M-Pesa receipt number is added if the callback arrives later.";

function createReconciler({
  Payment,
  Request,
  queryStkPush,
  fulfillSuccessfulPayment,
  notifyPaymentFailed = async () => {},
  logger = console,
}) {
  const unlockRequest = (requestId) =>
    Request.findByIdAndUpdate(requestId, { $set: { paymentInProgress: false } });

  // Daraja can no longer tell us what happened. Stop retrying, free the request, flag for an admin.
  async function abandon(payment, now) {
    const flagged = await Payment.findOneAndUpdate(
      { _id: payment._id, status: "Pending" },
      { $set: {
        status: "Failed",
        resultCode: "UNRESOLVED",
        needsReview: true,
        reconciledAt: new Date(now),
        reconcileNote: "Daraja could not confirm this payment after 24 hours. Check the M-Pesa statement before refunding or retrying.",
      } },
      { new: true }
    );
    if (flagged) await unlockRequest(payment.request);
    return { id: String(payment._id), action: flagged ? "flagged" : "skip" };
  }

  async function reconcilePayment(payment, now = Date.now()) {
    const decision = decideReconciliation(payment, now);
    if (decision === "skip" || decision === "wait") return { id: String(payment._id), action: decision };

    if (decision === "flag_unconfirmed") {
      // No Daraja identifiers, so we cannot ask Daraja. Free the student to retry
      // and flag the record so an admin can check the M-Pesa statement.
      const flagged = await Payment.findOneAndUpdate(
        { _id: payment._id, status: "Pending", transactionReference: { $in: [null, ""] } },
        { $set: {
          status: "Failed",
          resultCode: "UNCONFIRMED",
          needsReview: true,
          reconciledAt: new Date(now),
          reconcileNote: "No response was received from Daraja when the payment started. Check the M-Pesa statement before refunding or retrying.",
        } },
        { new: true }
      );
      if (flagged) await unlockRequest(payment.request);
      return { id: String(payment._id), action: flagged ? "flagged" : "skip" };
    }

    let result;
    try {
      result = await queryStkPush(payment.transactionReference);
    } catch (err) {
      // Daraja answers "still processing" with an HTTP error, so errors are inconclusive.
      if (isAbandoned(payment, now)) return abandon(payment, now);
      return { id: String(payment._id), action: "unknown" };
    }

    const verdict = interpretStkQuery(result, payment);
    if (verdict.outcome === "unknown") {
      if (isAbandoned(payment, now)) return abandon(payment, now);
      return { id: String(payment._id), action: "unknown" };
    }

    const succeeded = verdict.outcome === "success";
    const claimed = await Payment.findOneAndUpdate(
      { _id: payment._id, status: "Pending" },
      { $set: {
        status: succeeded ? "Success" : "Failed",
        resultCode: verdict.resultCode,
        reconciledAt: new Date(now),
        reconcileNote: succeeded ? NO_RECEIPT_NOTE : `Declined or lapsed: ${verdict.description || verdict.resultCode}`,
      } },
      { new: true }
    );
    // A callback settled it while we were querying.
    if (!claimed) return { id: String(payment._id), action: "skip" };

    if (succeeded) {
      await fulfillSuccessfulPayment(claimed);
    } else {
      await unlockRequest(payment.request);
      await notifyPaymentFailed(claimed);
    }

    return { id: String(payment._id), action: succeeded ? "success" : "failed" };
  }

  async function reconcileStalePayments(now = Date.now()) {
    const cutoff = new Date(now - QUERY_AFTER_MS);
    const pending = await Payment.find({ status: "Pending", createdAt: { $lte: cutoff } })
      .sort({ createdAt: 1 })
      .limit(100);

    const results = [];
    for (const payment of pending) {
      try {
        results.push(await reconcilePayment(payment, now));
      } catch (err) {
        logger.error(`Reconciliation failed for payment ${payment._id}:`, err.message);
        results.push({ id: String(payment._id), action: "error" });
      }
    }
    return results;
  }

  function startReconciliationJob(intervalMs = 2 * 60 * 1000) {
    let running = false;
    const tick = async () => {
      if (running) return;
      running = true;
      try {
        const results = await reconcileStalePayments();
        const changed = results.filter((r) => ["success", "failed", "flagged"].includes(r.action));
        if (changed.length) logger.log(`Payment reconciliation settled ${changed.length} payment(s)`);
      } catch (err) {
        logger.error("Payment reconciliation run failed:", err.message);
      } finally {
        running = false;
      }
    };
    tick(); // a restart is exactly when callbacks may have been missed
    const timer = setInterval(tick, intervalMs);
    timer.unref();
    return timer;
  }

  return { reconcilePayment, reconcileStalePayments, startReconciliationJob };
}

module.exports = { createReconciler };
