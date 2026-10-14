const COUNTER_ID = "request-number";

async function nextRequestNumber({ Request, RequestCounter, generateRequestNumber }) {
  const counter = await RequestCounter.findOneAndUpdate(
    { _id: COUNTER_ID },
    { $inc: { sequence: 1 } },
    { new: true }
  );
  if (counter) return generateRequestNumber(counter.sequence);

  const [latest] = await Request.aggregate([
    { $match: { requestNumber: /^CC-\d{4}-\d+$/ } },
    {
      $project: {
        sequence: {
          $convert: {
            input: { $arrayElemAt: [{ $split: ["$requestNumber", "-"] }, 2] },
            to: "long",
            onError: 0,
            onNull: 0,
          },
        },
      },
    },
    { $group: { _id: null, sequence: { $max: "$sequence" } } },
  ]);
  const initialSequence = (latest?.sequence ?? 0) + 1;

  try {
    const created = await RequestCounter.create({
      _id: COUNTER_ID,
      sequence: initialSequence,
    });
    return generateRequestNumber(created.sequence);
  } catch (error) {
    // Another request may have initialized the singleton counter concurrently.
    if (error.code !== 11000) throw error;
    const incremented = await RequestCounter.findOneAndUpdate(
      { _id: COUNTER_ID },
      { $inc: { sequence: 1 } },
      { new: true }
    );
    if (!incremented) throw error;
    return generateRequestNumber(incremented.sequence);
  }
}

module.exports = nextRequestNumber;
