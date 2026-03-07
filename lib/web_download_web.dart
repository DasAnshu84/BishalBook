// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

void downloadFileWeb(String csvContent, String fileName) {
  final bytes = csvContent.codeUnits;
  final blob = html.Blob([bytes], 'text/csv');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..click();
  html.Url.revokeObjectUrl(url);
}
