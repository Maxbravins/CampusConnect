// Turns raw SMTP failures into plain-language fixes (written for Brevo's SMTP relay).

const REQUIRED_ENV = ["SMTP_HOST", "SMTP_USER", "SMTP_PASS", "SMTP_FROM"];

function missingEmailEnv(env) {
  return REQUIRED_ENV.filter((name) => !env[name] || !String(env[name]).trim());
}

function diagnoseEmailError(err) {
  const text = `${err?.message || ""} ${err?.response || ""}`;
  const code = err?.code;
  const responseCode = err?.responseCode;

  if (/unauthori[sz]ed ip/i.test(text) || (responseCode === 525 && /5\.7\.1/.test(text))) {
    return "Brevo is blocking this computer's IP address. In Brevo, open Security and add your current public IP under Authorised IPs (search \"what is my IP\" to find it), or turn IP blocking off while developing. Home IPs change, so this can come back.";
  }
  if (code === "EAUTH" || responseCode === 535 || /invalid login|authentication failed/i.test(text)) {
    return "Brevo rejected the SMTP login. SMTP_USER must be the SMTP login shown in Brevo under SMTP & API (not your account password), and SMTP_PASS must be an SMTP key from the same page (not an API key).";
  }
  if (["ECONNECTION", "ETIMEDOUT", "ESOCKET", "ENOTFOUND", "EDNS", "ECONNREFUSED"].includes(code)) {
    return "Cannot reach the SMTP server. Check SMTP_HOST (smtp-relay.brevo.com) and SMTP_PORT (587), and that your network or firewall allows outbound connections on port 587.";
  }
  if (responseCode === 554 || /sender|from address|not.*verified/i.test(text)) {
    return "The sender address was refused. SMTP_FROM must be a sender you have verified in Brevo.";
  }
  return "Unrecognised failure. The error message above is what the SMTP server returned.";
}

module.exports = { REQUIRED_ENV, missingEmailEnv, diagnoseEmailError };
