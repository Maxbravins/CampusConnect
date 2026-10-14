const test = require("node:test");
const assert = require("node:assert/strict");
const jwt = require("jsonwebtoken");
const User = require("../src/models/User");

process.env.JWT_SECRET = "test-secret-with-enough-randomness-1234";

const { protect, adminOnly } = require("../src/middleware/authMiddleware");
const originalFindById = User.findById;

test.after(() => {
  User.findById = originalFindById;
});

function mockUserLookup(user) {
  User.findById = () => ({ select: async () => user });
}

function run(middleware, req) {
  return new Promise((resolve) => {
    const res = {
      statusCode: 200,
      status(code) { this.statusCode = code; return this; },
      json(body) { resolve({ status: this.statusCode, body, nextCalled: false }); },
    };
    middleware(req, res, () => resolve({ status: 200, nextCalled: true, req }));
  });
}

test("protect rejects requests without a bearer token", async () => {
  const result = await run(protect, { headers: {} });
  assert.equal(result.status, 401);
  assert.equal(result.nextCalled, false);
});

test("protect rejects malformed, tampered, and expired tokens", async () => {
  const malformed = await run(protect, { headers: { authorization: "Bearer not-a-jwt" } });
  assert.equal(malformed.status, 401);

  const wrongSecret = jwt.sign({ id: "1", role: "admin" }, "a-different-secret");
  const tampered = await run(protect, { headers: { authorization: `Bearer ${wrongSecret}` } });
  assert.equal(tampered.status, 401);

  const expired = jwt.sign({ id: "1", role: "student" }, process.env.JWT_SECRET, { expiresIn: -10 });
  const expiredResult = await run(protect, { headers: { authorization: `Bearer ${expired}` } });
  assert.equal(expiredResult.status, 401);
});

test("protect accepts a valid token and attaches id and role", async () => {
  const id = "507f1f77bcf86cd799439011";
  mockUserLookup({ _id: id, role: "student", status: "active" });
  const token = jwt.sign({ id, role: "student" }, process.env.JWT_SECRET);
  const result = await run(protect, { headers: { authorization: `Bearer ${token}` } });
  assert.equal(result.nextCalled, true);
  assert.equal(result.req.user.id, id);
  assert.equal(result.req.user.role, "student");
});

test("protect rejects an inactive account", async () => {
  mockUserLookup({ role: "student", status: "inactive" });
  const token = jwt.sign({ id: "507f1f77bcf86cd799439011", role: "student" }, process.env.JWT_SECRET);
  const result = await run(protect, { headers: { authorization: `Bearer ${token}` } });
  assert.equal(result.status, 401);
  assert.equal(result.nextCalled, false);
});

test("protect uses the account's current role instead of the token role", async () => {
  mockUserLookup({ role: "student", status: "active" });
  const token = jwt.sign({ id: "507f1f77bcf86cd799439011", role: "admin" }, process.env.JWT_SECRET);
  const result = await run(protect, { headers: { authorization: `Bearer ${token}` } });
  assert.equal(result.nextCalled, true);
  assert.equal(result.req.user.role, "student");
});

test("adminOnly blocks students and missing users, allows admins", async () => {
  assert.equal((await run(adminOnly, { user: { role: "student" } })).status, 403);
  assert.equal((await run(adminOnly, {})).status, 403);
  assert.equal((await run(adminOnly, { user: { role: "admin" } })).nextCalled, true);
});
