const User = require("../models/User");
const Request = require("../models/Request");
const Payment = require("../models/Payment");

function csvEscape(value) {
  return `"${String(value ?? "").replace(/"/g, '""')}"`;
}

// GET /api/reports/dashboard (admin only)
async function getDashboardStats(req, res, next) {
  try {
    const [
      totalStudents,
      totalRequests,
      pendingRequests,
      completedRequests,
      successfulPaymentsAgg,
      recentRequests,
      recentTransactions,
    ] = await Promise.all([
      User.countDocuments({ role: "student" }),
      Request.countDocuments(),
      Request.countDocuments({ status: "Pending" }),
      Request.countDocuments({ status: "Completed" }),
      Payment.aggregate([
        { $match: { status: "Success" } },
        { $group: { _id: null, count: { $sum: 1 }, total: { $sum: "$amount" } } },
      ]),
      Request.find()
        .populate("student", "fullName")
        .populate("service", "name")
        .sort({ createdAt: -1 })
        .limit(5),
      Payment.find({ status: "Success" })
        .populate("student", "fullName")
        .sort({ createdAt: -1 })
        .limit(5),
    ]);

    const successfulPayments = successfulPaymentsAgg[0] || { count: 0, total: 0 };

    res.json({
      totalStudents,
      totalRequests,
      pendingRequests,
      completedRequests,
      successfulPaymentsCount: successfulPayments.count,
      successfulPaymentsTotal: successfulPayments.total,
      recentRequests,
      recentTransactions,
    });
  } catch (err) {
    next(err);
  }
}

// GET /api/reports/export/requests (admin only)
async function exportRequestsCsv(req, res, next) {
  try {
    const requests = await Request.find()
      .populate("student", "fullName email")
      .populate("service", "name fee")
      .sort({ createdAt: -1 });

    const header = [
      "Request Number",
      "Student Name",
      "Student Email",
      "Service",
      "Fee",
      "Status",
      "Submitted At",
    ].join(",");

    const rows = requests.map((r) => {
      const studentName = r.student ? r.student.fullName : "";
      const studentEmail = r.student ? r.student.email : "";
      const serviceName = r.service ? r.service.name : "";
      const fee = r.service ? r.service.fee : "";
      const submitted = r.submittedAt ? new Date(r.submittedAt).toISOString() : "";

      return [
        csvEscape(r.requestNumber),
        csvEscape(studentName),
        csvEscape(studentEmail),
        csvEscape(serviceName),
        csvEscape(fee),
        csvEscape(r.status),
        csvEscape(submitted),
      ].join(",");
    });

    const csv = [header, ...rows].join("\n");

    res.setHeader("Content-Type", "text/csv");
    res.setHeader("Content-Disposition", "attachment; filename=campusconnect_requests.csv");
    res.send(csv);
  } catch (err) {
    next(err);
  }
}

// GET /api/reports/export/payments (admin only)
async function exportPaymentsCsv(req, res, next) {
  try {
    const payments = await Payment.find()
      .populate("student", "fullName email")
      .populate({ path: "request", populate: { path: "service", select: "name" } })
      .sort({ createdAt: -1 });

    const header = [
      "Student Name",
      "Student Email",
      "Service",
      "Amount",
      "Phone Number",
      "Transaction Reference",
      "Status",
      "Date",
    ].join(",");

    const rows = payments.map((p) => {
      const studentName = p.student ? p.student.fullName : "";
      const studentEmail = p.student ? p.student.email : "";
      const serviceName = p.request && p.request.service ? p.request.service.name : "";
      const date = p.createdAt ? new Date(p.createdAt).toISOString() : "";

      return [
        csvEscape(studentName),
        csvEscape(studentEmail),
        csvEscape(serviceName),
        csvEscape(p.amount),
        csvEscape(p.phoneNumber),
        csvEscape(p.transactionReference || ""),
        csvEscape(p.status),
        csvEscape(date),
      ].join(",");
    });

    const csv = [header, ...rows].join("\n");

    res.setHeader("Content-Type", "text/csv");
    res.setHeader("Content-Disposition", "attachment; filename=campusconnect_payments.csv");
    res.send(csv);
  } catch (err) {
    next(err);
  }
}

module.exports = { getDashboardStats, exportRequestsCsv, exportPaymentsCsv };