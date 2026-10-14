// Usage:  npm run check:push -- student@example.com
// Sends a real test push to the device that user last logged in on.
require("dotenv").config();
const mongoose = require("mongoose");
const connectDB = require("../src/config/db");
const User = require("../src/models/User");
const { sendPushToUser } = require("../src/services/pushService");
const { diagnosePushResult, maskToken } = require("../src/utils/pushDiagnostics");

(async () => {
  const email = (process.argv[2] || "").trim().toLowerCase();
  if (!email) {
    console.error("Usage: npm run check:push -- student@example.com");
    process.exit(1);
  }

  await connectDB();
  try {
    const user = await User.findOne({ email });
    if (!user) {
      console.error(`No user found with email ${email}`);
      process.exitCode = 1;
      return;
    }

    console.log(`User        : ${user.fullName} (${user.role})`);
    console.log(`Device token: ${maskToken(user.fcmToken)}`);
    console.log(`Firebase key: ${process.env.FIREBASE_SERVICE_ACCOUNT_PATH || "(FIREBASE_SERVICE_ACCOUNT_PATH not set)"}`);

    const result = await sendPushToUser(user, {
      title: "CampusConnect test",
      body: "If you can see this, push notifications work.",
      data: { type: "test" },
    });

    console.log(`\nResult: ${JSON.stringify(result)}`);
    console.log(`\n${diagnosePushResult(result)}`);
    if (!result.sent) process.exitCode = 1;
  } finally {
    await mongoose.disconnect();
  }
})();
