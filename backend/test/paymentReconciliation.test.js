const test = require("node:test");
const assert = require("node:assert/strict");
const {
  QUERY_AFTER_MS,
  UNCONFIRMED_AFTER_MS,
  ABANDON_AFTER_MS,
  isAbandoned,
  decideReconciliation,
  interpretStkQuery,
} = require("../src/utils/paymentReconciliation");
const { createReconciler } = require("../src/services/paymentReconciliationService");

const NOW = Date.parse("2026-10-14T12:00:00Z");
const minutesAgo = (m) => new Date(NOW - m * 60 * 1000);

const basePayment = (overrides = {}) => ({
  _id: "pay1",
  request: "req1",
  student: "stu1",
  amount: 250,
  phoneNumber: "254712345678",
  status: "Pending",
  transactionReference: "ws_CO_1",
  merchantRequestId: "merchant-1",
  createdAt: minutesAgo(10),
  ...overrides,
});

// ---------- pure decision logic ----------

test("decideReconciliation waits for the STK prompt to lapse before querying", () => {
  assert.equal(decideReconciliation(basePayment({ createdAt: minutesAgo(1) }), NOW), "wait");
  assert.equal(decideReconciliation(basePayment({ createdAt: minutesAgo(3) }), NOW), "query");
  assert.equal(QUERY_AFTER_MS, 3 * 60 * 1000);
});

test("decideReconciliation never touches settled payments", () => {
  assert.equal(decideReconciliation(basePayment({ status: "Success" }), NOW), "skip");
  assert.equal(decideReconciliation(basePayment({ status: "Failed" }), NOW), "skip");
});

test("payments without Daraja ids are flagged only after the long grace period", () => {
  const orphan = { transactionReference: undefined, merchantRequestId: undefined };
  assert.equal(decideReconciliation(basePayment({ ...orphan, createdAt: minutesAgo(10) }), NOW), "wait");
  assert.equal(decideReconciliation(basePayment({ ...orphan, createdAt: minutesAgo(15) }), NOW), "flag_unconfirmed");
  assert.equal(UNCONFIRMED_AFTER_MS, 15 * 60 * 1000);
});

test("interpretStkQuery maps Daraja result codes to outcomes", () => {
  const p = basePayment();
  const ids = { CheckoutRequestID: "ws_CO_1", MerchantRequestID: "merchant-1" };
  assert.equal(interpretStkQuery({ ...ids, ResultCode: "0" }, p).outcome, "success");
  assert.equal(interpretStkQuery({ ...ids, ResultCode: 0 }, p).outcome, "success");
  assert.equal(interpretStkQuery({ ...ids, ResultCode: "1032", ResultDesc: "Cancelled" }, p).outcome, "failed");
  assert.equal(interpretStkQuery({ ...ids, ResultCode: "1" }, p).outcome, "failed");
});

test("interpretStkQuery refuses to decide on mismatched or incomplete responses", () => {
  const p = basePayment();
  const ids = { CheckoutRequestID: "ws_CO_1", MerchantRequestID: "merchant-1" };
  assert.equal(interpretStkQuery({ ...ids, CheckoutRequestID: "other", ResultCode: "0" }, p).outcome, "unknown");
  assert.equal(interpretStkQuery({ ...ids, MerchantRequestID: "other", ResultCode: "0" }, p).outcome, "unknown");
  assert.equal(interpretStkQuery({ ...ids }, p).outcome, "unknown");
  assert.equal(interpretStkQuery({ ...ids, ResultCode: "abc" }, p).outcome, "unknown");
  assert.equal(interpretStkQuery({ errorCode: "500.001.1001" }, p).outcome, "unknown");
  assert.equal(interpretStkQuery(undefined, p).outcome, "unknown");
});

// ---------- reconciler with fake persistence ----------

function harness({ payments, queryResult, queryError }) {
  const store = new Map(payments.map((p) => [p._id, { ...p }]));
  const unlocked = [];
  const fulfilled = [];

  const matches = (doc, filter) => Object.entries(filter).every(([key, cond]) => {
    if (cond && typeof cond === "object" && "$in" in cond) return cond.$in.includes(doc[key] ?? null);
    return doc[key] === cond;
  });

  const Payment = {
    async findOneAndUpdate(filter, update) {
      const doc = [...store.values()].find((d) => matches(d, filter));
      if (!doc) return null;
      Object.assign(doc, update.$set);
      return { ...doc };
    },
    find() {
      const docs = [...store.values()].filter((d) => d.status === "Pending");
      return { sort: () => ({ limit: async () => docs.map((d) => ({ ...d })) }) };
    },
  };
  const Request = { async findByIdAndUpdate(id, update) { unlocked.push({ id, ...update.$set }); } };
  const queries = [];
  const reconciler = createReconciler({
    Payment,
    Request,
    queryStkPush: async (id) => {
      queries.push(id);
      if (queryError) throw queryError;
      return queryResult;
    },
    fulfillSuccessfulPayment: async (p) => { fulfilled.push(p._id); },
    logger: { log() {}, error() {} },
  });
  return { reconciler, store, unlocked, fulfilled, queries };
}

const confirmed = { CheckoutRequestID: "ws_CO_1", MerchantRequestID: "merchant-1", ResultCode: "0" };

test("a lost callback for a paid STK push is recovered through the query", async () => {
  const h = harness({ payments: [basePayment()], queryResult: confirmed });
  const result = await h.reconciler.reconcilePayment(basePayment(), NOW);
  assert.equal(result.action, "success");
  assert.equal(h.store.get("pay1").status, "Success");
  assert.equal(h.store.get("pay1").resultCode, "0");
  assert.deepEqual(h.fulfilled, ["pay1"]);
  assert.equal(h.unlocked.length, 0);
});

test("a cancelled or lapsed STK push is marked failed and the request is unlocked", async () => {
  const h = harness({
    payments: [basePayment()],
    queryResult: { ...confirmed, ResultCode: "1032", ResultDesc: "Request cancelled by user" },
  });
  const result = await h.reconciler.reconcilePayment(basePayment(), NOW);
  assert.equal(result.action, "failed");
  assert.equal(h.store.get("pay1").status, "Failed");
  assert.equal(h.store.get("pay1").resultCode, "1032");
  assert.deepEqual(h.unlocked, [{ id: "req1", paymentInProgress: false }]);
  assert.equal(h.fulfilled.length, 0);
});

test("a query error leaves the payment pending and the request locked", async () => {
  const h = harness({ payments: [basePayment()], queryError: new Error("500.001.1001 still processing") });
  const result = await h.reconciler.reconcilePayment(basePayment(), NOW);
  assert.equal(result.action, "unknown");
  assert.equal(h.store.get("pay1").status, "Pending");
  assert.equal(h.unlocked.length, 0);
  assert.equal(h.fulfilled.length, 0);
});

test("a payment younger than three minutes is not queried at all", async () => {
  const young = basePayment({ createdAt: minutesAgo(1) });
  const h = harness({ payments: [young], queryResult: confirmed });
  const result = await h.reconciler.reconcilePayment(young, NOW);
  assert.equal(result.action, "wait");
  assert.equal(h.queries.length, 0);
});

test("an unreferenced payment is flagged for review, unlocked, and never queried", async () => {
  const orphan = basePayment({ transactionReference: undefined, merchantRequestId: undefined, createdAt: minutesAgo(20) });
  const h = harness({ payments: [orphan], queryResult: confirmed });
  const result = await h.reconciler.reconcilePayment(orphan, NOW);
  assert.equal(result.action, "flagged");
  const saved = h.store.get("pay1");
  assert.equal(saved.status, "Failed");
  assert.equal(saved.resultCode, "UNCONFIRMED");
  assert.equal(saved.needsReview, true);
  assert.deepEqual(h.unlocked, [{ id: "req1", paymentInProgress: false }]);
  assert.equal(h.queries.length, 0);
});

test("if a callback settles the payment mid-reconcile, nothing is applied twice", async () => {
  const h = harness({ payments: [basePayment()], queryResult: confirmed });
  h.store.get("pay1").status = "Success"; // callback won the race after we read the stale copy
  const result = await h.reconciler.reconcilePayment(basePayment(), NOW);
  assert.equal(result.action, "skip");
  assert.equal(h.fulfilled.length, 0);
});

test("reconcileStalePayments handles each payment independently", async () => {
  const good = basePayment({ _id: "good" });
  const bad = basePayment({ _id: "bad", transactionReference: "ws_CO_2", merchantRequestId: "merchant-2" });
  const h = harness({ payments: [good, bad], queryResult: confirmed });
  const results = await h.reconciler.reconcileStalePayments(NOW);
  const byId = Object.fromEntries(results.map((r) => [r.id, r.action]));
  assert.equal(byId.good, "success");
  assert.equal(byId.bad, "unknown"); // Daraja answered for a different checkout id
  assert.deepEqual(h.fulfilled, ["good"]);
});

// ---------- giving up on payments Daraja can no longer answer for ----------

const hoursAgo = (h) => new Date(NOW - h * 60 * 60 * 1000);

test("isAbandoned only applies to pending payments older than 24 hours", () => {
  assert.equal(ABANDON_AFTER_MS, 24 * 60 * 60 * 1000);
  assert.equal(isAbandoned(basePayment({ createdAt: hoursAgo(23) }), NOW), false);
  assert.equal(isAbandoned(basePayment({ createdAt: hoursAgo(24) }), NOW), true);
  assert.equal(isAbandoned(basePayment({ createdAt: hoursAgo(48), status: "Success" }), NOW), false);
});

test("an old payment Daraja errors on is flagged, unlocked, and no longer pending", async () => {
  const old = basePayment({ createdAt: hoursAgo(30) });
  const h = harness({ payments: [old], queryError: new Error("Daraja has no record of this checkout id") });
  const result = await h.reconciler.reconcilePayment(old, NOW);
  assert.equal(result.action, "flagged");
  const saved = h.store.get("pay1");
  assert.equal(saved.status, "Failed");
  assert.equal(saved.resultCode, "UNRESOLVED");
  assert.equal(saved.needsReview, true);
  assert.deepEqual(h.unlocked, [{ id: "req1", paymentInProgress: false }]);
});

test("an old payment with an unusable Daraja answer is also flagged", async () => {
  const old = basePayment({ createdAt: hoursAgo(30) });
  const h = harness({ payments: [old], queryResult: { errorCode: "500.001.1001" } });
  const result = await h.reconciler.reconcilePayment(old, NOW);
  assert.equal(result.action, "flagged");
  assert.equal(h.store.get("pay1").needsReview, true);
});

test("an old payment Daraja still answers for is settled normally, not flagged", async () => {
  const old = basePayment({ createdAt: hoursAgo(30) });
  const h = harness({ payments: [old], queryResult: confirmed });
  const result = await h.reconciler.reconcilePayment(old, NOW);
  assert.equal(result.action, "success");
  assert.equal(h.store.get("pay1").needsReview, undefined);
  assert.deepEqual(h.fulfilled, ["pay1"]);
});

test("a recent payment with a query error is never flagged", async () => {
  const recent = basePayment({ createdAt: hoursAgo(2) });
  const h = harness({ payments: [recent], queryError: new Error("still processing") });
  const result = await h.reconciler.reconcilePayment(recent, NOW);
  assert.equal(result.action, "unknown");
  assert.equal(h.store.get("pay1").status, "Pending");
});
