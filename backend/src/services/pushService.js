const admin = require("firebase-admin");
const path = require("path");

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
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });
    initialized = true;
    console.log("Firebase Admin initialized — push notifications enabled.");
    return true;
  } catch (err) {
    console.warn(`Could not initialize Firebase Admin (${err.message}). Push notifications are disabled.`);
    return false;
  }
}

/**
 * Sends a push notification to a single user, if they have a registered
 * FCM token. Never throws — a failed/expired token or missing Firebase
 * config should never break the request/payment flow that triggered it.
 */
async function sendPushToUser(user, { title, body, data = {} }) {
  if (!user || !user.fcmToken) return;
  if (!ensureInitialized()) return;

  // FCM data payload values must all be strings.
  const stringData = Object.fromEntries(
    Object.entries(data).map(([key, value]) => [key, String(value)])
  );

  try {
    await admin.messaging().send({
      token: user.fcmToken,
      notification: { title, body },
      data: stringData,
    });
  } catch (err) {
    // Common benign cases: token expired/uninstalled app. Just log and move on.
    console.warn(`Push notification failed for user ${user._id}: ${err.message}`);
  }
}

module.exports = { sendPushToUser };
