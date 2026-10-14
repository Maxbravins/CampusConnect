const test = require("node:test");
const assert = require("node:assert/strict");

const {
  isValidRequestStatus,
  canAdminTransitionRequest,
  adminRequestNextStatuses,
} = require("../src/utils/requestStatusTransitions");

test("admins cannot mark an unpaid request as paid", () => {
  assert.equal(canAdminTransitionRequest("Payment Required", "Paid"), false);
  assert.equal(canAdminTransitionRequest("Pending", "Paid"), false);
});

test("admins can progress paid requests through processing and completion", () => {
  assert.deepEqual(adminRequestNextStatuses("Paid"), ["Processing", "Completed"]);
  assert.equal(canAdminTransitionRequest("Paid", "Processing"), true);
  assert.equal(canAdminTransitionRequest("Paid", "Completed"), true);
  assert.equal(canAdminTransitionRequest("Processing", "Completed"), true);
});

test("completed and cancelled requests cannot be moved by admins", () => {
  assert.deepEqual(adminRequestNextStatuses("Completed"), []);
  assert.equal(canAdminTransitionRequest("Cancelled", "Processing"), false);
  assert.equal(isValidRequestStatus("Paid"), true);
  assert.equal(isValidRequestStatus("not-a-status"), false);
});
