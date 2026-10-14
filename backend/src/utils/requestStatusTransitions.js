const ADMIN_TRANSITIONS = {
  Pending: ["Payment Required"],
  Paid: ["Processing", "Completed"],
  Processing: ["Completed"],
};

const VALID_STATUSES = [
  "Pending",
  "Payment Required",
  "Paid",
  "Processing",
  "Completed",
  "Cancelled",
];

function isValidRequestStatus(status) {
  return VALID_STATUSES.includes(status);
}

function canAdminTransitionRequest(currentStatus, nextStatus) {
  return ADMIN_TRANSITIONS[currentStatus]?.includes(nextStatus) ?? false;
}

function adminRequestNextStatuses(currentStatus) {
  return ADMIN_TRANSITIONS[currentStatus] ?? [];
}

module.exports = {
  VALID_STATUSES,
  isValidRequestStatus,
  canAdminTransitionRequest,
  adminRequestNextStatuses,
};
