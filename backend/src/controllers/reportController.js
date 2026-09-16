const User = require("../models/User");
const Request = require("../models/Request");
const Payment = require("../models/Payment");

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

module.exports = { getDashboardStats };
