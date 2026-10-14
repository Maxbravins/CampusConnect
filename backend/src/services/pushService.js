const { initializeApp, cert } = require("firebase-admin/app");
const { getMessaging } = require("firebase-admin/messaging");
const path = require("path");
const User = require("../models/User");

let initialized = false;

function ensureInitialized() {
  if (initialized) return true;

  const keyPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH;
  if (!keyPath) {
    console.warn(
      "FIREBASE_SERVICE_ACCOUNT_PATH not set — push notifications are disabled. " +
        "In-app notifications will still work."
    );
    return false;
  }

  try {
    const serviceAccount = require(path.resolve(keyPath));
    initializeApp({
      credential: cert(serviceAccount),
    });
    initialized = true;
    console.log("Firebase Admin initialized — push notifications enabled.");
    return true;
  } catch (err) {
    console.warn(`Could not initialize Firebase Admin (${err.message}). Push notifications are disabled.`);
    return false;
  }
}

// FCM error codes that mean this token will never work again (app uninstalled, token rotated, malformed).
const DEAD_TOKEN_CODES = new Set([
  "messaging/registration-token-not-registered",
  "messaging/invalid-registration-token",
]);

const MULTICAST_BATCH_SIZE = 500; // FCM limit per multicast call

function createPushService({ getMessaging, isReady, User, logger = console }) {
  function buildPayload({ title, body, data = {} }) {
    return {
      notification: { title, body },
      // FCM data payload values must all be strings.
      data: Object.fromEntries(Object.entries(data).map(([key, value]) => [key, String(value)])),
      // Deliver promptly even when an Android device is in battery-saving idle mode.
      android: { priority: "high" },
    };
  }

  const dropTokens = (tokens) =>
    User.updateMany({ fcmToken: { $in: tokens } }, { $unset: { fcmToken: 1 } });

  /**
   * Sends a push to one user. Never throws — a failed token or missing Firebase
   * config must never break the request/payment flow that triggered it.
   * Resolves to { sent: true } or { sent: false, reason, code? }.
   */
  async function sendPushToUser(user, payload) {
    if (!user || !user.fcmToken) return { sent: false, reason: "no-token" };
    if (!isReady()) return { sent: false, reason: "not-configured" };

    try {
      await getMessaging().send({ token: user.fcmToken, ...buildPayload(payload) });
      return { sent: true };
    } catch (err) {
      if (DEAD_TOKEN_CODES.has(err.code)) {
        await dropTokens([user.fcmToken]).catch(() => {});
        logger.warn(`Removed dead push token for user ${user._id} (${err.code})`);
        return { sent: false, reason: "token-removed", code: err.code };
      }
      logger.warn(`Push notification failed for user ${user._id}: ${err.message}`);
      return { sent: false, reason: "error", code: err.code, message: err.message };
    }
  }

  /**
   * Sends the same push to many users (e.g. an announcement), in batches.
   * Dead tokens are removed. Never throws. Resolves to { sent, failed, removed }.
   */
  async function sendPushToUsers(users, payload) {
    const tokens = [...new Set((users || []).map((u) => u && u.fcmToken).filter(Boolean))];
    const totals = { sent: 0, failed: 0, removed: 0 };
    if (!tokens.length || !isReady()) return totals;

    const message = buildPayload(payload);
    const dead = [];

    for (let i = 0; i < tokens.length; i += MULTICAST_BATCH_SIZE) {
      const batch = tokens.slice(i, i + MULTICAST_BATCH_SIZE);
      try {
        const result = await getMessaging().sendEachForMulticast({ tokens: batch, ...message });
        result.responses.forEach((r, index) => {
          if (r.success) {
            totals.sent += 1;
          } else {
            totals.failed += 1;
            if (DEAD_TOKEN_CODES.has(r.error && r.error.code)) dead.push(batch[index]);
          }
        });
      } catch (err) {
        totals.failed += batch.length;
        logger.warn(`Push batch failed: ${err.message}`);
      }
    }

    if (dead.length) {
      await dropTokens(dead).catch(() => {});
      totals.removed = dead.length;
    }
    return totals;
  }

  return { sendPushToUser, sendPushToUsers };
}

module.exports = {
  ...createPushService({ getMessaging, isReady: ensureInitialized, User }),
  createPushService,
  DEAD_TOKEN_CODES,
};
