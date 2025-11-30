// lib/screens/analyst/analyst_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:jalnetra01/models/reading_model.dart';
// Note: Ensure your WaterReading model has the necessary fields (siteId, waterLevel, timestamp, etc.)

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

  // --- EXPORT FUNCTION ---
  void _exportData(BuildContext context) {
    if (readings.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No ${title.toLowerCase()} data available to export.'),
        ),
      );
      return;
    }

    // Determine filename based on the title passed (e.g., "Danger Zones")
    final filename = title.toLowerCase().replaceAll(' ', '_');
    int rowCount = readings.length;

    // --- MOCK EXPORT PROCESS ---
    // In a real application, you would:
    // 1. Convert `readings` list to a CSV string.
    // 2. Use packages like `path_provider` and `permission_handler` to save the file locally.

    // Simulate delay for file processing
    Future.delayed(const Duration(milliseconds: 800), () {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Exported $rowCount records to $filename.csv.'),
          backgroundColor: statusColor.withOpacity(0.8),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: statusColor.withOpacity(0.8),
        actions: [
          // 🚀 EXPORT BUTTON PLACED IN TOP RIGHT CORNER
          IconButton(
            icon: const Icon(Icons.file_download, color: Colors.white),
            tooltip: 'Export to CSV',
            onPressed: () => _exportData(context), // Trigger the export logic
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
