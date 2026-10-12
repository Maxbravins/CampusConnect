require("dotenv").config();
const path = require("path");
const { initializeApp, cert } = require("firebase-admin/app");
const { getMessaging } = require("firebase-admin/messaging");

const token = process.argv.slice(2).join("").replace(/\s+/g, "");
if (!token) {
  console.error("Usage: node scripts/send-test-push.js <fcm-token>");
  process.exit(1);
}

initializeApp({
  credential: cert(require(path.resolve(process.env.FIREBASE_SERVICE_ACCOUNT_PATH))),
});

getMessaging()
  .send({
    token,
    notification: { title: "CampusConnect", body: "Test push from backend" },
    data: { source: "test" },
  })
  .then((id) => console.log("Sent:", id))
  .catch((e) => console.error("Failed:", e.message))
  .finally(() => process.exit());