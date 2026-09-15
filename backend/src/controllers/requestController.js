const Request = require("../models/Request");
const Service = require("../models/Service");
const generateRequestNumber = require("../utils/generateRequestNumber");
const { sendRequestUpdateEmail, sendCompletionEmail } = require("../services/emailService");
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
    }

    res.json(request);
  } catch (err) {
    next(err);
  }
}

module.exports = { createRequest, myRequests, listRequests, updateStatus };
