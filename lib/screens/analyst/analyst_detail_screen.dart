// lib/screens/analyst/analyst_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:jalnetra01/models/reading_model.dart';
import 'package:path_provider/path_provider.dart'; // Import for file paths
import 'dart:io'; // Import for File operations
import 'package:csv/csv.dart'; // Import for CSV conversion
import 'package:share_plus/share_plus.dart'; // Import for sharing files

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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Preparing ${title.toLowerCase()} data for export...'),
        backgroundColor: Colors.blueGrey,
      ),
    );

    try {
      // 1. Prepare CSV data
      List<List<dynamic>> csvData = [];
      // Add header row
      csvData.add(['Site ID', 'Water Level (m)', 'Timestamp', 'Is Verified']);
      // Add reading data
      for (var reading in readings) {
        csvData.add([
          reading.siteId,
          reading.waterLevel.toStringAsFixed(2),
          reading.timestamp.toLocal().toIso8601String().substring(
            0,
            16,
          ), // Format timestamp
          reading.isVerified ? 'Yes' : 'No', // Assuming isVerified is a field
        ]);
      }

      String csvString = const ListToCsvConverter().convert(csvData);

      // 2. Get a temporary directory to store the file
      final directory = await getTemporaryDirectory();
      final filename = '${title.toLowerCase().replaceAll(' ', '_')}_data.csv';
      final filePath = '${directory.path}/$filename';
      final file = File(filePath);

      // 3. Write CSV string to the file
      await file.writeAsString(csvString);

      // 4. Show success bar AND trigger native share sheet
      if (context.mounted) {
        // Show success bar first
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Successfully exported ${readings.length} records. Sharing file...',
            ),
            backgroundColor: statusColor.withOpacity(0.8),
          ),
        );

        // Then open the share sheet
        await Share.shareXFiles(
          [XFile(filePath)],
          text: 'JALNETRA: ${title} data export.',
          subject: 'Water Reading Data',
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
      print('Error exporting data: $e'); // Log the error for debugging
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: statusColor.withOpacity(0.8),
        actions: [
          // EXPORT BUTTON
          IconButton(
            icon: const Icon(
              Icons.file_download,
              color: Colors.white,
            ), // Changed icon to share
            tooltip: 'Export & Share Data',
            onPressed: () =>
                _exportAndShareData(context), // Call the new function
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
                      // Optional: Navigate to a single reading detail view
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
