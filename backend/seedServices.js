// One-time script to add the campus services listed in the project
// proposal. Safe to re-run — it upserts by service name, so it won't
// create duplicates if a service already exists.
require("dotenv").config();
const mongoose = require("mongoose");
const Service = require("./src/models/Service");

const services = [
  {
    name: "Student ID Replacement",
    description: "Replace a lost or damaged student ID card",
    fee: 500,
    processingDays: 1,
  },
  {
    name: "Transcript Request",
    description: "Official academic transcript for the current or a past semester",
    fee: 800,
    processingDays: 5,
  },
  {
    name: "Certificate Request",
    description: "Official certificate of completion or a course-specific certificate",
    fee: 1000,
    processingDays: 7,
  },
  {
    name: "Clearance Request",
    description: "Institutional clearance certificate (e.g. for graduation or transfer)",
    fee: 600,
    processingDays: 3,
  },
  {
    name: "Accommodation Request",
    description: "Request or renew campus accommodation for the upcoming term",
    fee: 1500,
    processingDays: 4,
  },
];

async function run() {
  await mongoose.connect(process.env.MONGO_URI);
  console.log("Connected to MongoDB.");

  for (const service of services) {
    const result = await Service.updateOne(
      { name: service.name },
      { $setOnInsert: service },
      { upsert: true }
    );
    if (result.upsertedCount > 0) {
      console.log(`Created: ${service.name}`);
    } else {
      console.log(`Already exists, skipped: ${service.name}`);
    }
  }

  await mongoose.disconnect();
  console.log("Done.");
}

run().catch((err) => {
  console.error("Seeding failed:", err.message);
  process.exit(1);
});
