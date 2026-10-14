const test = require("node:test");
const assert = require("node:assert/strict");
const nextRequestNumber = require("../src/utils/nextRequestNumber");

const format = (sequence) => `CC-2026-${String(sequence).padStart(6, "0")}`;

test("initializes the counter after the highest existing request number", async () => {
  let created;
  const result = await nextRequestNumber({
    Request: { aggregate: async () => [{ sequence: 87 }] },
    RequestCounter: {
      findOneAndUpdate: async () => null,
      create: async (value) => (created = value),
    },
    generateRequestNumber: format,
  });

  assert.equal(result, "CC-2026-000088");
  assert.deepEqual(created, { _id: "request-number", sequence: 88 });
});

test("atomically increments an initialized counter", async () => {
  let query;
  let update;
  const result = await nextRequestNumber({
    Request: { aggregate: async () => assert.fail("Should not seed an existing counter") },
    RequestCounter: {
      findOneAndUpdate: async (filter, operation, options) => {
        query = { filter, operation, options };
        return { sequence: 89 };
      },
    },
    generateRequestNumber: format,
  });

  assert.equal(result, "CC-2026-000089");
  assert.deepEqual(query.filter, { _id: "request-number" });
  assert.deepEqual(query.operation, { $inc: { sequence: 1 } });
  assert.deepEqual(query.options, { new: true });
});

test("recovers when concurrent first requests initialize the counter", async () => {
  let incremented = false;
  const duplicateKey = Object.assign(new Error("duplicate key"), { code: 11000 });
  const result = await nextRequestNumber({
    Request: { aggregate: async () => [{ sequence: 87 }] },
    RequestCounter: {
      findOneAndUpdate: async () => {
        if (!incremented) return null;
        return { sequence: 89 };
      },
      create: async () => {
        incremented = true;
        throw duplicateKey;
      },
    },
    generateRequestNumber: format,
  });

  assert.equal(result, "CC-2026-000089");
});
