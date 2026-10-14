const test = require("node:test");
const assert = require("node:assert/strict");

const { MAX_PAGE_SIZE, parsePagination, findPage } = require("../src/utils/pagination");
const { escapeRegexLiteral } = require("../src/utils/search");

test("pagination defaults and caps the page size", () => {
  assert.deepEqual(parsePagination({}), { page: 1, limit: 25 });
  assert.deepEqual(parsePagination({ page: "3", limit: "500" }), {
    page: 3,
    limit: MAX_PAGE_SIZE,
  });
});

test("pagination rejects invalid page and limit values", () => {
  assert.equal(parsePagination({ page: "0" }), null);
  assert.equal(parsePagination({ limit: "-2" }), null);
  assert.equal(parsePagination({ page: "not-a-number" }), null);
});

test("findPage clamps pages past the end and returns pagination metadata", async () => {
  const calls = {};
  const query = {
    sort(value) { calls.sort = value; return this; },
    skip(value) { calls.skip = value; return this; },
    limit(value) { calls.limit = value; return Promise.resolve(["last-page"]); },
  };
  const model = {
    countDocuments: async () => 51,
    find: (filter) => { calls.filter = filter; return query; },
  };

  const result = await findPage({ model, filter: { status: "Paid" }, page: 99, limit: 25 });

  assert.deepEqual(result, {
    items: ["last-page"],
    page: 3,
    limit: 25,
    total: 51,
    totalPages: 3,
  });
  assert.deepEqual(calls.filter, { status: "Paid" });
  assert.deepEqual(calls.sort, { createdAt: -1, _id: -1 });
  assert.equal(calls.skip, 50);
  assert.equal(calls.limit, 25);
});

test("user search text is escaped and treated literally", () => {
  const input = "a.*[b]";
  const pattern = new RegExp(escapeRegexLiteral(input));
  assert.equal(pattern.test("a.*[b]"), true);
  assert.equal(pattern.test("anything"), false);
});
