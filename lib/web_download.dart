/// Conditional export: uses the real dart:html impl on web,
/// falls back to a no-op stub on mobile / desktop.
export 'web_download_stub.dart'
    if (dart.library.html) 'web_download_web.dart';
