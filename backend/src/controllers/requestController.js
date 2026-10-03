const Request = require("../models/Request");
const Service = require("../models/Service");
const Notification = require("../models/Notification");
const generateRequestNumber = require("../utils/generateRequestNumber");
const { sendRequestUpdateEmail, sendCompletionEmail } = require("../services/emailService");
const { sendPushToUser } = require("../services/pushService");
const User = require("../models/User");

// POST /api/requests — student submits a request
async function createRequest(req, res, next) {
  try {
    const { serviceId } = req.body;
    const service = await Service.findById(serviceId);
    if (!service || service.status !== "active") {
      return res.status(400).json({ message: "Invalid or inactive service" });
    }

    const count = await Request.countDocuments();
    const requestNumber = generateRequestNumber(count + 1);

    const request = await Request.create({
      requestNumber,
      student: req.user.id,
      service: service._id,
      status: "Payment Required",
    });

    res.status(201).json(request);
  } catch (err) {
    next(err);
  }
}

// GET /api/requests/mine — student's own requests
async function myRequests(req, res, next) {
  try {
    const requests = await Request.find({ student: req.user.id })
      .populate("service", "name fee")
      .sort({ createdAt: -1 });
    res.json(requests);
  } catch (err) {
    next(err);
  }
}

// GET /api/requests — admin, all requests (optionally filter by status)
async function listRequests(req, res, next) {
  try {
    const filter = {};
    if (req.query.status) filter.status = req.query.status;

    const requests = await Request.find(filter)
      .populate("student", "fullName email studentId")
      .populate("service", "name fee")
      .sort({ createdAt: -1 });
    res.json(requests);
  } catch (err) {
    next(err);
  }
}

// PUT /api/requests/:id/status — admin updates status
async function updateStatus(req, res, next) {
  try {
    const { status } = req.body;
    const request = await Request.findById(req.params.id).populate("service", "name");
    if (!request) return res.status(404).json({ message: "Request not found" });

    request.status = status;
    if (status === "Completed") request.completedAt = new Date();
    await request.save();

    const student = await User.findById(request.student);
    if (student) {
      if (status === "Completed") {
        sendCompletionEmail(student.email, request.service.name);
      } else {
        sendRequestUpdateEmail(student.email, request.service.name, status);
      }

      await Notification.create({
        user: student._id,
        title: "Request Update",
        message: `Your ${request.service.name} request (${request.requestNumber}) is now: ${status}.`,
      });

      sendPushToUser(student, {
        title: "Request Update",
        body: `Your ${request.service.name} request (${request.requestNumber}) is now: ${status}.`,
        data: { type: "request_update", requestId: request._id.toString(), status },
      });
    }

    res.json(request);
  } catch (err) {
    next(err);
  }
}

// PATCH /api/requests/:id/cancel — student cancels their own unpaid request
async function cancelRequest(req, res, next) {
  try {
    const request = await Request.findById(req.params.id);
    if (!request) return res.status(404).json({ message: "Request not found" });

    if (request.student.toString() !== req.user.id) {
      return res.status(403).json({ message: "You can only cancel your own requests" });
    }

    if (request.status !== "Payment Required" && request.status !== "Pending") {
      return res.status(400).json({
        message: "Only unpaid requests can be cancelled. This request has already been paid or processed.",
      });
    }

    request.status = "Cancelled";
    await request.save();

    res.json(request);
  } catch (err) {
    next(err);
  }
}

module.exports = { createRequest, myRequests, listRequests, updateStatus, cancelRequest };
