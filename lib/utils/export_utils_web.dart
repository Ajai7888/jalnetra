// lib/utils/export_utils_web.dart

import 'dart:convert';
import 'dart:html' as html;

Future<void> saveAndShareCsv({
  required String filename,
  required String csvContent,
  required String shareText,
}) async {
  // Convert to bytes
  final bytes = utf8.encode(csvContent);
  final blob = html.Blob([bytes], 'text/csv');

  // Create a download link and click it programmatically
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();

  html.Url.revokeObjectUrl(url);
}
