import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Mobile implementation — saves to temp dir and opens share sheet.
Future<void> downloadFileWeb(String csvContent, String fileName) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$fileName');
  await file.writeAsString(csvContent);
  await SharePlus.instance.share(
    ShareParams(
      files: [XFile(file.path)],
      subject: fileName,
    ),
  );
}
