const mongoose = require("mongoose");

const requestCounterSchema = new mongoose.Schema({
  _id: { type: String, required: true },
  sequence: { type: Number, required: true, min: 0 },
});

module.exports = mongoose.model("RequestCounter", requestCounterSchema);
