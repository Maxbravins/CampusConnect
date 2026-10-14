const DEFAULT_PAGE_SIZE = 25;
const MAX_PAGE_SIZE = 100;

function positiveInteger(value, fallback) {
  if (value === undefined) return fallback;
  if (typeof value !== "string" || !/^\d+$/.test(value)) return null;

  const number = Number(value);
  return Number.isSafeInteger(number) && number > 0 ? number : null;
}

function parsePagination(query) {
  const page = positiveInteger(query.page, 1);
  const requestedLimit = positiveInteger(query.limit, DEFAULT_PAGE_SIZE);

  if (page === null || requestedLimit === null) return null;
  return { page, limit: Math.min(requestedLimit, MAX_PAGE_SIZE) };
}

async function findPage({ model, filter, populate = [], select, page, limit }) {
  const total = await model.countDocuments(filter);
  const totalPages = Math.ceil(total / limit);
  const currentPage = totalPages === 0 ? 1 : Math.min(page, totalPages);
  let query = model.find(filter);

  if (select) query = query.select(select);
  for (const population of populate) query = query.populate(...population);

  const items = await query
    .sort({ createdAt: -1, _id: -1 })
    .skip((currentPage - 1) * limit)
    .limit(limit);

  return { items, page: currentPage, limit, total, totalPages };
}

module.exports = { DEFAULT_PAGE_SIZE, MAX_PAGE_SIZE, parsePagination, findPage };
