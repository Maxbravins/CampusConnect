// Turns the result of sendPushToUser into a plain-language explanation for the check:push script.

function diagnosePushResult(result) {
  if (result.sent) {
    return "FCM accepted the message. If nothing appears: on the web, push only shows as a system notification when the app tab is in the background (a focused tab shows an in-app banner instead). Also check browser notification permission and Windows Focus Assist.";
  }

  switch (result.reason) {
    case "no-token":
      return "This user has no device token saved. Log in as them on the phone or browser, allow notifications when asked, then run this again.";
    case "not-configured":
      return "Firebase Admin is not set up. Set FIREBASE_SERVICE_ACCOUNT_PATH in .env to the service account JSON file, then restart.";
    case "token-removed":
      return "FCM said this device token is no longer valid (app reinstalled, site data cleared, or token rotated). It was removed. Log in again on the device to register a fresh one.";
    default:
  }

  switch (result.code) {
    case "messaging/third-party-auth-error":
    case "messaging/mismatched-credential":
    case "messaging/sender-id-mismatch":
      return "The service account key belongs to a different Firebase project than the app. Download the key from the same project used in the app's Firebase config (campusconnect project).";
    case "messaging/authentication-error":
    case "app/invalid-credential":
      return "Firebase rejected the service account credentials. Generate a new private key in Firebase Console, Project settings, Service accounts.";
    case "messaging/invalid-argument":
      return "FCM rejected the message or token as malformed.";
    case "messaging/quota-exceeded":
    case "messaging/server-unavailable":
    case "messaging/internal-error":
      return "Temporary FCM problem. Try again in a minute.";
    default:
      return "Unrecognised failure. The error above is what FCM returned.";
  }
}

function maskToken(token) {
  if (!token) return "(none)";
  return token.length <= 14 ? "…" : `${token.slice(0, 8)}…${token.slice(-4)} (${token.length} chars)`;
}

module.exports = { diagnosePushResult, maskToken };
