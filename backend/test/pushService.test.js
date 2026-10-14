const test = require("node:test");
const assert = require("node:assert/strict");
const { createPushService } = require("../src/services/pushService");
const { diagnosePushResult, maskToken } = require("../src/utils/pushDiagnostics");
const { missingEmailEnv, diagnoseEmailError } = require("../src/utils/emailDiagnostics");

function harness({ sendImpl, multicastImpl, ready = true } = {}) {
  const sent = [];
  const multicasts = [];
  const unsets = [];
  const warnings = [];
  const messaging = {
    async send(message) {
      sent.push(message);
      if (sendImpl) return sendImpl(message);
      return "message-id";
    },
    async sendEachForMulticast(message) {
      multicasts.push(message);
      if (multicastImpl) return multicastImpl(message);
      return { responses: message.tokens.map(() => ({ success: true })) };
    },
  };
  const User = {
    async updateMany(filter, update) { unsets.push({ filter, update }); },
  };
  const service = createPushService({
    getMessaging: () => messaging,
    isReady: () => ready,
    User,
    logger: { warn: (m) => warnings.push(m), log() {}, error() {} },
  });
  return { service, sent, multicasts, unsets, warnings };
}

const user = { _id: "u1", fcmToken: "token-abc" };
const payload = { title: "Hi", body: "There", data: { requestId: 42, status: "Paid" } };

// ---------- sendPushToUser ----------

test("sends a notification with string-only data and high Android priority", async () => {
  const h = harness();
  const result = await h.service.sendPushToUser(user, payload);
  assert.deepEqual(result, { sent: true });
  assert.equal(h.sent.length, 1);
  assert.equal(h.sent[0].token, "token-abc");
  assert.deepEqual(h.sent[0].notification, { title: "Hi", body: "There" });
  assert.deepEqual(h.sent[0].data, { requestId: "42", status: "Paid" });
  assert.equal(h.sent[0].android.priority, "high");
});

test("skips users without a token and does not call FCM", async () => {
  const h = harness();
  assert.deepEqual(await h.service.sendPushToUser({ _id: "u2" }, payload), { sent: false, reason: "no-token" });
  assert.deepEqual(await h.service.sendPushToUser(null, payload), { sent: false, reason: "no-token" });
  assert.equal(h.sent.length, 0);
});

test("does nothing when Firebase is not configured", async () => {
  const h = harness({ ready: false });
  assert.deepEqual(await h.service.sendPushToUser(user, payload), { sent: false, reason: "not-configured" });
  assert.equal(h.sent.length, 0);
});

test("a dead token is removed from the database", async () => {
  const err = Object.assign(new Error("not registered"), { code: "messaging/registration-token-not-registered" });
  const h = harness({ sendImpl: () => { throw err; } });
  const result = await h.service.sendPushToUser(user, payload);
  assert.equal(result.sent, false);
  assert.equal(result.reason, "token-removed");
  assert.deepEqual(h.unsets, [{ filter: { fcmToken: { $in: ["token-abc"] } }, update: { $unset: { fcmToken: 1 } } }]);
});

test("a temporary FCM error keeps the token and never throws", async () => {
  const err = Object.assign(new Error("unavailable"), { code: "messaging/server-unavailable" });
  const h = harness({ sendImpl: () => { throw err; } });
  const result = await h.service.sendPushToUser(user, payload);
  assert.equal(result.reason, "error");
  assert.equal(result.code, "messaging/server-unavailable");
  assert.equal(h.unsets.length, 0);
  assert.equal(h.warnings.length, 1);
});

// ---------- sendPushToUsers ----------

test("broadcast de-duplicates tokens and ignores users without one", async () => {
  const h = harness();
  const totals = await h.service.sendPushToUsers(
    [{ fcmToken: "a" }, { fcmToken: "a" }, { fcmToken: "b" }, {}, null],
    payload
  );
  assert.deepEqual(totals, { sent: 2, failed: 0, removed: 0 });
  assert.deepEqual(h.multicasts[0].tokens, ["a", "b"]);
});

test("broadcast sends at most 500 tokens per FCM call", async () => {
  const h = harness();
  const users = Array.from({ length: 1201 }, (_, i) => ({ fcmToken: `t${i}` }));
  const totals = await h.service.sendPushToUsers(users, payload);
  assert.deepEqual(h.multicasts.map((m) => m.tokens.length), [500, 500, 201]);
  assert.equal(totals.sent, 1201);
});

test("broadcast removes only the dead tokens it was told about", async () => {
  const dead = { success: false, error: { code: "messaging/registration-token-not-registered" } };
  const flaky = { success: false, error: { code: "messaging/server-unavailable" } };
  const h = harness({
    multicastImpl: () => ({ responses: [{ success: true }, dead, flaky] }),
  });
  const totals = await h.service.sendPushToUsers([{ fcmToken: "ok" }, { fcmToken: "dead" }, { fcmToken: "flaky" }], payload);
  assert.deepEqual(totals, { sent: 1, failed: 2, removed: 1 });
  assert.deepEqual(h.unsets[0].filter, { fcmToken: { $in: ["dead"] } });
});

test("a failing batch is counted but does not throw", async () => {
  const h = harness({ multicastImpl: () => { throw new Error("network down"); } });
  const totals = await h.service.sendPushToUsers([{ fcmToken: "a" }, { fcmToken: "b" }], payload);
  assert.deepEqual(totals, { sent: 0, failed: 2, removed: 0 });
});

test("broadcast with nobody to notify makes no FCM call", async () => {
  const h = harness();
  assert.deepEqual(await h.service.sendPushToUsers([], payload), { sent: 0, failed: 0, removed: 0 });
  assert.equal(h.multicasts.length, 0);
});

// ---------- diagnostics ----------

test("push diagnostics explain each outcome", () => {
  assert.match(diagnosePushResult({ sent: true }), /background/);
  assert.match(diagnosePushResult({ sent: false, reason: "no-token" }), /no device token/);
  assert.match(diagnosePushResult({ sent: false, reason: "not-configured" }), /FIREBASE_SERVICE_ACCOUNT_PATH/);
  assert.match(diagnosePushResult({ sent: false, reason: "token-removed" }), /removed/);
  assert.match(diagnosePushResult({ sent: false, reason: "error", code: "messaging/third-party-auth-error" }), /different Firebase project/);
  assert.match(diagnosePushResult({ sent: false, reason: "error", code: "something-new" }), /Unrecognised/);
});

test("maskToken never reveals the whole token", () => {
  const token = "abcdefghijklmnopqrstuvwxyz0123456789";
  const masked = maskToken(token);
  assert.ok(!masked.includes(token));
  assert.equal(maskToken(undefined), "(none)");
});

test("email diagnostics recognise the Brevo failures", () => {
  assert.match(diagnoseEmailError(new Error("Invalid login: 525 5.7.1 Unauthorized IP address")), /IP address/);
  assert.match(diagnoseEmailError(Object.assign(new Error("Invalid login"), { code: "EAUTH", responseCode: 535 })), /SMTP login/);
  assert.match(diagnoseEmailError(Object.assign(new Error("timeout"), { code: "ETIMEDOUT" })), /Cannot reach/);
  assert.match(diagnoseEmailError(Object.assign(new Error("rejected"), { responseCode: 554 })), /SMTP_FROM/);
  assert.match(diagnoseEmailError(new Error("???")), /Unrecognised/);
});

test("missingEmailEnv lists only absent or blank settings", () => {
  assert.deepEqual(missingEmailEnv({ SMTP_HOST: "h", SMTP_USER: "u", SMTP_PASS: " ", SMTP_FROM: "f" }), ["SMTP_PASS"]);
  assert.deepEqual(missingEmailEnv({ SMTP_HOST: "h", SMTP_USER: "u", SMTP_PASS: "p", SMTP_FROM: "f" }), []);
});
