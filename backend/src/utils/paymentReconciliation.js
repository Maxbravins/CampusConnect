// Pure decision logic for reconciling payments that never got a final callback.

// The STK prompt on the customer's phone lapses well before this, so asking
// Daraja after 3 minutes gives a definitive answer instead of "still processing".
const QUERY_AFTER_MS = 3 * 60 * 1000;

// A payment with no Daraja identifiers cannot be queried. After this long every
// late callback should have arrived, so we stop blocking the student and flag it.
const UNCONFIRMED_AFTER_MS = 15 * 60 * 1000;

// Daraja stops answering STK queries for old checkout ids. Past this age we stop
// asking, free the request, and hand the payment to an admin instead of retrying forever.
const ABANDON_AFTER_MS = 24 * 60 * 60 * 1000;

function hasDarajaIds(payment) {
  return Boolean(payment.transactionReference && payment.merchantRequestId);
}

// -> "skip" | "wait" | "query" | "flag_unconfirmed"
function decideReconciliation(payment, now = Date.now()) {
  if (payment.status !== "Pending") return "skip";
  const age = now - new Date(payment.createdAt).getTime();
  if (hasDarajaIds(payment)) return age >= QUERY_AFTER_MS ? "query" : "wait";
  return age >= UNCONFIRMED_AFTER_MS ? "flag_unconfirmed" : "wait";
}

function isAbandoned(payment, now = Date.now()) {
  return payment.status === "Pending" &&
    now - new Date(payment.createdAt).getTime() >= ABANDON_AFTER_MS;
}

// Turns a Daraja STK query response into a definitive outcome, or "unknown".
// "unknown" means: leave the payment Pending and try again later.
function interpretStkQuery(result, payment) {
  const sameIds =
    String(result?.CheckoutRequestID) === payment.transactionReference &&
    String(result?.MerchantRequestID) === payment.merchantRequestId;
  if (!sameIds) return { outcome: "unknown" };

  const code = result?.ResultCode;
  if (code === undefined || code === null) return { outcome: "unknown" };
  const text = String(code).trim();
  if (!/^\d+$/.test(text)) return { outcome: "unknown" };
  if (text === "0") return { outcome: "success", resultCode: "0", description: result.ResultDesc };
  return { outcome: "failed", resultCode: text, description: result.ResultDesc };
}

module.exports = {
  QUERY_AFTER_MS,
  UNCONFIRMED_AFTER_MS,
  ABANDON_AFTER_MS,
  isAbandoned,
  decideReconciliation,
  interpretStkQuery,
};
