// lib/screens/analyst/analyst_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:jalnetra01/models/reading_model.dart';
import 'package:csv/csv.dart'; // For CSV conversion

// NEW: platform-aware export helper
import 'package:jalnetra01/utils/export_utils.dart';

class AnalystDetailScreen extends StatelessWidget {
  final String title;
  final List<WaterReading> readings;
  final Color statusColor;

  const AnalystDetailScreen({
    super.key,
    required this.title,
    required this.readings,
    required this.statusColor,
  });

  // --- ACTUAL EXPORT AND SHARE FUNCTION ---
  Future<void> _exportAndShareData(BuildContext context) async {
    if (readings.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No ${title.toLowerCase()} data available to export.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // Inform user that export started
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Preparing ${title.toLowerCase()} data for export...'),
        backgroundColor: Colors.blueGrey,
      ),
    );

    try {
      // 1. Prepare CSV data
      final List<List<dynamic>> csvData = [];

      // Header row
      csvData.add(['Site ID', 'Water Level (m)', 'Timestamp', 'Is Verified']);

      // Rows
      for (var reading in readings) {
        csvData.add([
          reading.siteId,
          reading.waterLevel.toStringAsFixed(2),
          reading.timestamp.toLocal().toIso8601String().substring(0, 16),
          reading.isVerified ? 'Yes' : 'No',
        ]);
      }

      final String csvString = const ListToCsvConverter().convert(csvData);

      // 2. Filename for export
      final filename = '${title.toLowerCase().replaceAll(' ', '_')}_data.csv';

      // 3. Use platform-aware helper
      await saveAndShareCsv(
        filename: filename,
        csvContent: csvString,
        shareText: 'JALNETRA: $title data export.',
      );

      // 4. Success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully exported ${readings.length} records.'),
            backgroundColor: statusColor.withOpacity(0.8),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      // For debugging
      // ignore: avoid_print
      print('Error exporting data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: statusColor.withOpacity(0.8),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download, color: Colors.white),
            tooltip: 'Export & Share Data',
            onPressed: () => _exportAndShareData(context),
          ),
        ],
      ),
      body: readings.isEmpty
          ? Center(
              child: Text(
                'No verified readings found for $title.',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12.0),
              itemCount: readings.length,
              itemBuilder: (context, index) {
                final reading = readings[index];
                return Card(
                  color: Theme.of(context).cardColor,
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ListTile(
                    leading: Icon(Icons.water_drop, color: statusColor),
                    title: Text(
                      "Site ID: ${reading.siteId}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      "Level: ${reading.waterLevel.toStringAsFixed(2)} m\n"
                      "Time: ${reading.timestamp.toLocal().toString().substring(0, 16)}",
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: statusColor,
                    ),
                    isThreeLine: true,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Viewing full details for ${reading.siteId}',
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
