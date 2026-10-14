const Service = require("../models/Service");

// GET /api/services (optional ?category=... filter)
async function listServices(req, res, next) {
  try {
    const filter = req.user?.role === "admin" ? {} : { status: "active" };
    if (req.query.category && req.query.category !== "All") {
      filter.category = req.query.category;
    }
    const services = await Service.find(filter).sort({ createdAt: -1 });
    res.json(services);
  } catch (err) {
    next(err);
  }
}

// POST /api/services (admin)
async function createService(req, res, next) {
  try {
    const { name, description, fee, processingDays, category } = req.body;
    const daysToProcess = processingDays ?? 1;
    if (typeof name !== "string" || !name.trim()) {
      return res.status(400).json({ message: "Service name is required" });
    }
    if (!Number.isSafeInteger(fee) || fee < 1) {
      return res.status(400).json({ message: "Fee must be a whole number of at least KES 1" });
    }
    if (!Number.isSafeInteger(daysToProcess) || daysToProcess < 1) {
      return res.status(400).json({ message: "Processing days must be a positive whole number" });
    }
    if (description != null && typeof description !== "string") {
      return res.status(400).json({ message: "Description must be text" });
    }
    if (category != null && typeof category !== "string") {
      return res.status(400).json({ message: "Category must be text" });
    }

    const service = await Service.create({
      name: name.trim(),
      description,
      fee,
      processingDays: daysToProcess,
      category: category?.trim() || "General",
    });
    res.status(201).json(service);
  } catch (err) {
    next(err);
  }
}

// PUT /api/services/:id (admin)
async function updateService(req, res, next) {
  try {
    const service = await Service.findByIdAndUpdate(req.params.id, req.body, { new: true });
    if (!service) return res.status(404).json({ message: "Service not found" });
    res.json(service);
  } catch (err) {
    next(err);
  }
}

// DELETE /api/services/:id (admin) — soft delete
async function deactivateService(req, res, next) {
  try {
    const service = await Service.findByIdAndUpdate(
      req.params.id,
      { status: "inactive" },
      { new: true }
    );
    if (!service) return res.status(404).json({ message: "Service not found" });
    res.json(service);
  } catch (err) {
    next(err);
  }
}

module.exports = { listServices, createService, updateService, deactivateService };
