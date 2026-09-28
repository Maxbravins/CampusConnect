import 'dart:html' as html;

/// Triggers a browser download of [content] as a file named [filename].
void downloadCsv(String filename, String content) {
  final bytes = html.Blob([content], 'text/csv');
  final url = html.Url.createObjectUrlFromBlob(bytes);

  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();

  html.Url.revokeObjectUrl(url);
}