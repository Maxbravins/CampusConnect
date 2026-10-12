const test = require("node:test");
const assert = require("node:assert/strict");
const {
  normalizeKenyanPhone,
  callbackMetadata,
  callbackMatchesPayment,
  stkQueryConfirmsPayment,
} = require("../src/utils/paymentValidation");
const { hashOtp, otpMatches } = require("../src/utils/otpSecurity");

test("normalizes common Kenyan mobile formats", () => {
  assert.equal(normalizeKenyanPhone("0712 345 678"), "254712345678");
  assert.equal(normalizeKenyanPhone("+254 712 345678"), "254712345678");
  assert.equal(normalizeKenyanPhone("712345678"), "254712345678");
  assert.equal(normalizeKenyanPhone("12345"), null);
});

test("validates callback identifiers, amount, phone, and receipt against the payment", () => {
  const payment = {
    transactionReference: "ws_CO_example",
    merchantRequestId: "merchant-example",
    amount: 250,
    phoneNumber: "254712345678",
  };
  const callback = {
    MerchantRequestID: "merchant-example",
    CheckoutRequestID: "ws_CO_example",
    CallbackMetadata: { Item: [
      { Name: "Amount", Value: 250 },
      { Name: "MpesaReceiptNumber", Value: "QWX1234567" },
      { Name: "PhoneNumber", Value: 712345678 },
    ] },
  };

  assert.equal(callbackMatchesPayment(callback, payment), true);
  assert.equal(callbackMetadata(callback).MpesaReceiptNumber, "QWX1234567");
  assert.equal(callbackMatchesPayment({ ...callback, CheckoutRequestID: "other" }, payment), false);
  assert.equal(callbackMatchesPayment({ ...callback, CallbackMetadata: { Item: [{ Name: "Amount", Value: 1 }] } }, payment), false);
  assert.equal(stkQueryConfirmsPayment({
    CheckoutRequestID: payment.transactionReference,
    MerchantRequestID: payment.merchantRequestId,
    ResultCode: "0",
  }, payment), true);
  assert.equal(stkQueryConfirmsPayment({ ResultCode: "0" }, payment), false);
});

test("OTP hashes are one-way and compared only for six-digit input", () => {
  const secret = "test-secret-with-enough-randomness";
  const hashed = hashOtp("123456", secret);
  assert.notEqual(hashed, "123456");
  assert.equal(otpMatches(hashed, "123456", secret), true);
  assert.equal(otpMatches(hashed, "000000", secret), false);
  assert.equal(otpMatches(hashed, "12345", secret), false);
});
