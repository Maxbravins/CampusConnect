require("dotenv").config();
const app = require("./src/app");
const connectDB = require("./src/config/db");

const PORT = process.env.PORT || 5000;

if (!process.env.JWT_SECRET || process.env.JWT_SECRET.length < 32 || process.env.JWT_SECRET.startsWith("replace-with-")) {
  throw new Error("JWT_SECRET must be set to a random value of at least 32 characters.");
}

connectDB().then(() => {
  app.listen(PORT, () => console.log(`CampusConnect API running on port ${PORT}`));
});
