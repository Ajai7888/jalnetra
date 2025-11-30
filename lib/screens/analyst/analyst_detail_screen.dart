// lib/screens/analyst/analyst_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:jalnetra01/models/reading_model.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: statusColor.withOpacity(0.8),
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
