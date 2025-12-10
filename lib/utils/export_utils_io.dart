// lib/utils/export_utils_io.dart

import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<void> saveAndShareCsv({
  required String filename,
  required String csvContent,
  required String shareText,
}) async {
  // 1. Get temporary directory
  final directory = await getTemporaryDirectory();
  final filePath = '${directory.path}/$filename';
  final file = File(filePath);

  // 2. Write CSV to file
  await file.writeAsString(csvContent);

  // 3. Open native share sheet
  await Share.shareXFiles(
    [XFile(filePath)],
    text: shareText,
    subject: 'Water Reading Data',
  );
}
