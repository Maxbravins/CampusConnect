// Generates reference numbers like CC-2026-000125
function generateRequestNumber(sequence) {
  const year = new Date().getFullYear();
  const padded = String(sequence).padStart(6, "0");
  return `CC-${year}-${padded}`;
}

module.exports = generateRequestNumber;
