function normalizeKenyanPhone(value) {
  const digits = String(value || "").replace(/[\s()+-]/g, "");
  if (/^0[17]\d{8}$/.test(digits)) return `254${digits.slice(1)}`;
  if (/^[17]\d{8}$/.test(digits)) return `254${digits}`;
  if (/^254[17]\d{8}$/.test(digits)) return digits;
  return null;
}

function callbackMetadata(callback) {
  const items = callback?.CallbackMetadata?.Item;
  if (!Array.isArray(items)) return null;
  return Object.fromEntries(items.map(({ Name, Value }) => [Name, Value]));
}

function callbackMatchesPayment(callback, payment) {
  const metadata = callbackMetadata(callback);
  return Boolean(
    callback?.CheckoutRequestID &&
    callback.CheckoutRequestID === payment.transactionReference &&
    callback?.MerchantRequestID &&
    callback.MerchantRequestID === payment.merchantRequestId &&
    metadata &&
    Number(metadata.Amount) === payment.amount &&
    normalizeKenyanPhone(metadata.PhoneNumber) === normalizeKenyanPhone(payment.phoneNumber) &&
    typeof metadata.MpesaReceiptNumber === "string" &&
    metadata.MpesaReceiptNumber.length > 0
  );
}

function stkQueryConfirmsPayment(result, payment) {
  return String(result?.CheckoutRequestID) === payment.transactionReference &&
    String(result?.MerchantRequestID) === payment.merchantRequestId &&
    String(result?.ResultCode) === "0";
}

module.exports = { normalizeKenyanPhone, callbackMetadata, callbackMatchesPayment, stkQueryConfirmsPayment };
