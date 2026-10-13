// Production wiring for the reconciler.
const Payment = require("../models/Payment");
const Request = require("../models/Request");
const { queryStkPush } = require("./mpesaService");
const { fulfillSuccessfulPayment } = require("./paymentFulfillment");
const { createReconciler } = require("./paymentReconciliationService");

module.exports = createReconciler({ Payment, Request, queryStkPush, fulfillSuccessfulPayment });
