const test = require("node:test");
const assert = require("node:assert/strict");
const jwt = require("jsonwebtoken");

process.env.JWT_SECRET = "test-secret-with-enough-randomness-1234";

const app = require("../src/app");
const generateRequestNumber = require("../src/utils/generateRequestNumber");

let server;
let base;

test.before(async () => {
  await new Promise((resolve) => { server = app.listen(0, resolve); });
  base = `http://127.0.0.1:${server.address().port}`;
});

test.after(() => new Promise((resolve) => server.close(resolve)));

const tokenFor = (role) => jwt.sign({ id: "507f1f77bcf86cd799439011", role }, process.env.JWT_SECRET);
const auth = (role) => ({ authorization: `Bearer ${tokenFor(role)}` });

test("GET /api/health responds ok", async () => {
  const res = await fetch(`${base}/api/health`);
  assert.equal(res.status, 200);
  assert.deepEqual(await res.json(), { status: "ok" });
});

test("unknown routes return 404", async () => {
  const res = await fetch(`${base}/api/does-not-exist`);
  assert.equal(res.status, 404);
});

test("protected student routes require a token", async () => {
  for (const path of [
    "/api/requests/mine",
    "/api/notifications/mine",
    "/api/payments/mine",
    "/api/services",
    "/api/announcements",
    "/api/users/me",
  ]) {
    const res = await fetch(`${base}${path}`);
    assert.equal(res.status, 401, `${path} should be 401 without a token`);
  }
});

test("admin-only routes reject anonymous users and students", async () => {
  const id = "507f1f77bcf86cd799439011";
  const adminRoutes = [
    ["GET", "/api/requests"],
    ["PUT", `/api/requests/${id}/status`],
    ["GET", "/api/payments"],
    ["GET", "/api/reports/dashboard"],
    ["GET", "/api/reports/export/requests"],
    ["GET", "/api/reports/export/payments"],
    ["GET", "/api/users"],
    ["GET", `/api/users/${id}`],
    ["PUT", `/api/users/${id}/status`],
    ["POST", "/api/services"],
    ["PUT", `/api/services/${id}`],
    ["DELETE", `/api/services/${id}`],
    ["POST", "/api/announcements"],
  ];
  for (const [method, path] of adminRoutes) {
    const anon = await fetch(`${base}${path}`, { method });
    assert.equal(anon.status, 401, `${method} ${path} anonymous`);
    const student = await fetch(`${base}${path}`, { method, headers: auth("student") });
    assert.equal(student.status, 403, `${method} ${path} as student`);
  }
});

test("request numbers follow CC-YEAR-000000 format", () => {
  const year = new Date().getFullYear();
  assert.equal(generateRequestNumber(125), `CC-${year}-000125`);
  assert.equal(generateRequestNumber(1), `CC-${year}-000001`);
});
