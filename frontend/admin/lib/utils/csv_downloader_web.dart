import 'dart:js_interop';
import 'package:web/web.dart' as web;

/// Triggers a browser download of [content] as a file named [filename].
void downloadCsv(String filename, String content) {
  final blob = web.Blob(
    [content.toJS].toJS,
    web.BlobPropertyBag(type: 'text/csv'),
  );
  final url = web.URL.createObjectURL(blob);

  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = filename;
  anchor.click();

  web.URL.revokeObjectURL(url);
}
