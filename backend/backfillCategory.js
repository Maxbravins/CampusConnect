require("dotenv").config();
const mongoose = require("mongoose");
const Service = require("./src/models/Service");

async function run() {
  await mongoose.connect(process.env.MONGO_URI);
  const result = await Service.updateMany(
    { category: { $exists: false } },
    { $set: { category: "General" } }
  );
  console.log(`Updated ${result.modifiedCount} service(s) with default category "General".`);
  await mongoose.disconnect();
}

run().catch((err) => {
  console.error("Backfill failed:", err.message);
  process.exit(1);
});
