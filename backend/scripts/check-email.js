// Usage:
//   npm run check:email                      verify the SMTP login only
//   npm run check:email -- you@example.com   also send a real test message
require("dotenv").config();
const { transporter, sendEmail } = require("../src/services/emailService");
const { missingEmailEnv, diagnoseEmailError } = require("../src/utils/emailDiagnostics");

(async () => {
  const missing = missingEmailEnv(process.env);
  if (missing.length) {
    console.error(`Missing from .env: ${missing.join(", ")}`);
    process.exit(1);
  }

  console.log(`SMTP server : ${process.env.SMTP_HOST}:${process.env.SMTP_PORT || 587}`);
  console.log(`SMTP user   : ${process.env.SMTP_USER}`);
  console.log(`Sender      : ${process.env.SMTP_FROM}`);

  try {
    await transporter.verify();
    console.log("\nOK: connected and logged in to the SMTP server.");
  } catch (err) {
    console.error(`\nFAILED: ${err.message}`);
    console.error(`\nLikely fix: ${diagnoseEmailError(err)}`);
    process.exit(1);
  }

  const to = process.argv[2];
  if (!to) {
    console.log("Tip: run  npm run check:email -- you@example.com  to send a real test message.");
    return;
  }

  const result = await sendEmail(
    to,
    "CampusConnect email test",
    "If you are reading this, CampusConnect can send email."
  );
  if (result.ok) {
    console.log(`OK: test message accepted for ${to} (id ${result.messageId}). Check the inbox and spam folder.`);
  } else {
    console.error(`FAILED to send: ${result.error.message}`);
    console.error(`\nLikely fix: ${diagnoseEmailError(result.error)}`);
    process.exit(1);
  }
})();
