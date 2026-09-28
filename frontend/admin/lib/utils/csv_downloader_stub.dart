/// Fallback used on platforms without a browser (e.g. running tests).
void downloadCsv(String filename, String content) {
  throw UnsupportedError('CSV download is only supported on web.');
}
