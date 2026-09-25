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
    const service = await Service.create({
      name,
      description,
      fee,
      processingDays,
      category: category || "General",
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
