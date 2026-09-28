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
    category: "Administrative",
    fee: 500,
    processingDays: 1,
  },
  {
    name: "Transcript Request",
    description: "Official academic transcript for the current or a past semester",
    category: "Academic",
    fee: 800,
    processingDays: 5,
  },
  {
    name: "Certificate Request",
    description: "Official certificate of completion or a course-specific certificate",
    category: "Academic",
    fee: 1000,
    processingDays: 7,
  },
  {
    name: "Clearance Request",
    description: "Institutional clearance certificate (e.g. for graduation or transfer)",
    category: "Administrative",
    fee: 600,
    processingDays: 3,
  },
  {
    name: "Accommodation Request",
    description: "Request or renew campus accommodation for the upcoming term",
    category: "Accommodation",
    fee: 1500,
    processingDays: 4,
  },
  {
    name: "Fee Balance Statement",
    description: "Official statement of fees paid and outstanding balance",
    category: "Financial",
    fee: 200,
    processingDays: 2,
  },
  {
    name: "Library Fine Clearance",
    description: "Clear outstanding library fines before graduation or re-registration",
    category: "Financial",
    fee: 300,
    processingDays: 1,
  },
];

async function run() {
  await mongoose.connect(process.env.MONGO_URI);
  console.log("Connected to MongoDB.");

  for (const service of services) {
    const { category, ...rest } = service;
    const result = await Service.updateOne(
      { name: service.name },
      {
        $set: { category },
        $setOnInsert: rest,
      },
      { upsert: true }
    );
    if (result.upsertedCount > 0) {
      console.log(`Created: ${service.name} (${category})`);
    } else {
      console.log(`Already exists, category set to "${category}": ${service.name}`);
    }
  }

  await mongoose.disconnect();
  console.log("Done.");
}

run().catch((err) => {
  console.error("Seeding failed:", err.message);
  process.exit(1);
});