// Sends transactional emails via Brevo's SMTP relay
// (smtp-relay.brevo.com). Unlike Resend's default sandbox mode, Brevo's
// free tier (300 emails/day) allows sending to any recipient from day
// one — the "from" address just needs to match the email you signed up
// to Brevo with (or a verified sender/domain later).
const nodemailer = require("nodemailer");

const transporter = nodemailer.createTransport({
  host: process.env.SMTP_HOST,
  port: Number(process.env.SMTP_PORT) || 587,
  secure: false, // Brevo uses STARTTLS on 587, not implicit TLS
  auth: {
    user: process.env.SMTP_USER,
    pass: process.env.SMTP_PASS,
  },
});

async function sendEmail(to, subject, text) {
  try {
    await transporter.sendMail({
      from: process.env.SMTP_FROM,
      to,
      subject,
      text,
    });
  } catch (err) {
    console.error("Email send failed:", err.message);
  }
}

module.exports = {
  sendRegistrationEmail: (to, fullName) =>
    sendEmail(to, "Welcome to CampusConnect", `Hi ${fullName}, your account has been successfully created.`),

  sendPaymentEmail: (to, amount) =>
    sendEmail(to, "Payment received", `Your payment of KES ${amount} has been successfully received.`),

  sendRequestUpdateEmail: (to, serviceName, status) =>
    sendEmail(to, "Request update", `Your ${serviceName} request has changed to: ${status}.`),

  sendCompletionEmail: (to, serviceName) =>
    sendEmail(to, "Request completed", `Your ${serviceName} request has been completed.`),
};
