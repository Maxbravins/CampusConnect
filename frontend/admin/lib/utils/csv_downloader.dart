// Picks the right implementation at compile time: the web version when
// building for web, and a harmless stub everywhere else (e.g. tests).
export 'csv_downloader_stub.dart'
    if (dart.library.js_interop) 'csv_downloader_web.dart';
