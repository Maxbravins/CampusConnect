// Sends transactional emails via Brevo's SMTP relay
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

async function sendEmail(to, subject, text, html) {
  try {
    await transporter.sendMail({
      from: process.env.SMTP_FROM,
      to,
      subject,
      text,
      html,
    });
  } catch (err) {
    console.error("Email send failed:", err.message);
  }
}

function buildReceiptHtml(receipt) {
  return `
    <div style="font-family: Arial, sans-serif; max-width: 480px; margin: 0 auto;">
      <div style="background: #3F51B5; color: #ffffff; padding: 20px; border-radius: 8px 8px 0 0;">
        <h2 style="margin: 0;">CampusConnect</h2>
        <p style="margin: 4px 0 0; opacity: 0.9;">Payment Receipt</p>
      </div>
      <div style="border: 1px solid #e0e0e0; border-top: none; padding: 20px; border-radius: 0 0 8px 8px;">
        <table style="width: 100%; border-collapse: collapse;">
          <tr>
            <td style="padding: 8px 0; color: #666;">Service</td>
            <td style="padding: 8px 0; text-align: right; font-weight: bold;">${receipt.serviceName}</td>
          </tr>
          <tr>
            <td style="padding: 8px 0; color: #666;">Reference No.</td>
            <td style="padding: 8px 0; text-align: right; font-weight: bold;">${receipt.requestNumber}</td>
          </tr>
          <tr>
            <td style="padding: 8px 0; color: #666;">Transaction ID</td>
            <td style="padding: 8px 0; text-align: right;">${receipt.transactionReference || "N/A"}</td>
          </tr>
          <tr>
            <td style="padding: 8px 0; color: #666;">Phone Number</td>
            <td style="padding: 8px 0; text-align: right;">${receipt.phoneNumber}</td>
          </tr>
          <tr>
            <td style="padding: 8px 0; color: #666;">Date</td>
            <td style="padding: 8px 0; text-align: right;">${receipt.date}</td>
          </tr>
          <tr>
            <td style="padding: 12px 0 0; border-top: 2px solid #3F51B5; color: #3F51B5; font-size: 16px; font-weight: bold;">Amount Paid</td>
            <td style="padding: 12px 0 0; border-top: 2px solid #3F51B5; text-align: right; color: #3F51B5; font-size: 16px; font-weight: bold;">KES ${receipt.amount}</td>
          </tr>
        </table>
        <p style="margin-top: 20px; color: #999; font-size: 12px;">
          Thank you for using CampusConnect. Keep this receipt for your records.
        </p>
      </div>
    </div>
  `;
}

function buildReceiptText(receipt) {
  return (
    `CampusConnect - Payment Receipt\n\n` +
    `Service: ${receipt.serviceName}\n` +
    `Reference No.: ${receipt.requestNumber}\n` +
    `Transaction ID: ${receipt.transactionReference || "N/A"}\n` +
    `Phone Number: ${receipt.phoneNumber}\n` +
    `Date: ${receipt.date}\n` +
    `Amount Paid: KES ${receipt.amount}\n\n` +
    `Thank you for using CampusConnect. Keep this receipt for your records.`
  );
}

module.exports = {
  sendRegistrationEmail: (to, fullName) =>
    sendEmail(to, "Welcome to CampusConnect", `Hi ${fullName}, your account has been successfully created.`),

  sendPasswordResetOtp: (to, otp) =>
  sendEmail(
    to,
    "CampusConnect Password Reset OTP",
    `Your CampusConnect password reset OTP is: ${otp}. This code expires in 10 minutes.`
  ),

  // `receipt` is an object: { serviceName, requestNumber, amount,
  // transactionReference, phoneNumber, date }
  sendPaymentEmail: (to, receipt) =>
    sendEmail(
      to,
      "Payment Receipt - CampusConnect",
      buildReceiptText(receipt),
      buildReceiptHtml(receipt)
    ),

  sendRequestUpdateEmail: (to, serviceName, status) =>
    sendEmail(to, "Request update", `Your ${serviceName} request has changed to: ${status}.`),

  sendCompletionEmail: (to, serviceName) =>
    sendEmail(to, "Request completed", `Your ${serviceName} request has been completed.`),
};

