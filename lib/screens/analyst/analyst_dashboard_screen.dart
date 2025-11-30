// lib/screens/analyst/analyst_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // Chart library
import 'package:jalnetra01/common/firebase_service.dart';
import 'package:jalnetra01/models/reading_model.dart';
import 'package:jalnetra01/screens/auth/role_selection_screen.dart';
import 'package:jalnetra01/screens/common/profile_screen.dart';
import 'package:jalnetra01/screens/analyst/analyst_detail_screen.dart';

// --- Data Processor Class ---
class DashboardData {
  final int totalReceived;
  final int safeZone;
  final int dangerZones;
  final int warningsToday;
  final List<WaterReading> readings;

  DashboardData({
    required this.totalReceived,
    required this.safeZone,
    required this.dangerZones,
    required this.warningsToday,
    required this.readings,
  });
}

class AnalystDashboardScreen extends StatefulWidget {
  const AnalystDashboardScreen({super.key});

  @override
  State<AnalystDashboardScreen> createState() => _AnalystDashboardScreenState();
}

class _AnalystDashboardScreenState extends State<AnalystDashboardScreen> {
  static const double dangerThreshold = 4.0;
  static const double warningThreshold = 2.5;

  DashboardData _processReadings(List<WaterReading> allReadings) {
    int total = allReadings.length;
    int danger = 0;
    int warning = 0;
    int safe = 0;

    for (var reading in allReadings) {
      if (reading.waterLevel >= dangerThreshold) {
        danger++;
      } else if (reading.waterLevel >= warningThreshold) {
        warning++;
      } else {
        safe++;
      }
    }

    return DashboardData(
      totalReceived: total,
      safeZone: safe,
      dangerZones: danger,
      warningsToday: warning,
      readings: allReadings,
    );
  }

  // -------------------------------------------------------------------
  // NAVIGATION HANDLER
  // -------------------------------------------------------------------

  void _navigateToDetail(
    BuildContext context,
    DashboardData data, // Receives data object
    String viewKey,
    String title,
    Color color,
  ) {
    List<WaterReading> filteredList;

    if (viewKey == 'dataReceived') {
      filteredList = data.readings;
    } else if (viewKey == 'dangerZones') {
      filteredList = data.readings
          .where((r) => r.waterLevel >= dangerThreshold)
          .toList();
    } else if (viewKey == 'warningsToday') {
      filteredList = data.readings
          .where(
            (r) =>
                r.waterLevel >= warningThreshold &&
                r.waterLevel < dangerThreshold,
          )
          .toList();
    } else {
      // safeZone
      filteredList = data.readings
          .where((r) => r.waterLevel < warningThreshold)
          .toList();
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AnalystDetailScreen(
          title: title,
          readings: filteredList,
          statusColor: color,
        ),
      ),
    );
  }

  // -------------------------------------------------------------------
  // DATA EXPORT LOGIC
  // -------------------------------------------------------------------

  void _exportData(BuildContext context, DashboardData data, String viewKey) {
    List<WaterReading> filteredList;
    String filename;

    // Determine which dataset to export
    if (viewKey == 'dataReceived') {
      filteredList = data.readings;
      filename = 'all_readings';
    } else if (viewKey == 'dangerZones') {
      filteredList = data.readings
          .where((r) => r.waterLevel >= dangerThreshold)
          .toList();
      filename = 'danger_zone_readings';
    } else if (viewKey == 'warningsToday') {
      filteredList = data.readings
          .where(
            (r) =>
                r.waterLevel >= warningThreshold &&
                r.waterLevel < dangerThreshold,
          )
          .toList();
      filename = 'warning_readings';
    } else if (viewKey == 'safeZone') {
      filteredList = data.readings
          .where((r) => r.waterLevel < warningThreshold)
          .toList();
      filename = 'safe_zone_readings';
    } else {
      return;
    }

    if (filteredList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No data available to export for this category.'),
        ),
      );
      return;
    }

    // --- MOCK EXPORT PROCESS ---
    int rowCount = filteredList.length;

    // Simulate delay for file processing
    Future.delayed(const Duration(milliseconds: 800), () {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Successfully generated $filename.csv with $rowCount records.',
          ),
          backgroundColor: Colors.blueGrey,
        ),
      );
    });
  }

  // -------------------------------------------------------------------
  // UI BUILDERS
  // -------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('JALNETRA - Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'Profile',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await FirebaseService().signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RoleSelectionScreen(),
                  ),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<List<WaterReading>>(
        stream: FirebaseService().getAllVerifiedReadings(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final data = _processReadings(snapshot.data ?? []);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. TOP STATS GRID
                _buildStatsGrid(context, data),

                // *** EXPORT BUTTON IS REMOVED FROM HERE ***
                const SizedBox(height: 20),

                // 2. QUICK INSIGHTS / RADIAL BAR CHART
                _buildQuickInsights(context, data),
                const SizedBox(height: 20),

                // 3. DATA RECEIVED LIST (MOCK - Now Static)
                _buildDataReceivedList(context, data),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- WIDGET: EXPORT OPTIONS DIALOG BUTTON ---
  Widget _buildExportButton(BuildContext context, DashboardData data) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 12.0),
      child: OutlinedButton.icon(
        icon: const Icon(Icons.file_download, color: Colors.white),
        label: const Text(
          "Export Data (CSV)",
          style: TextStyle(color: Colors.white),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.white38),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onPressed: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text("Select Data to Export"),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildExportOption(
                      context,
                      data,
                      "All Received Data",
                      'dataReceived',
                    ),
                    _buildExportOption(
                      context,
                      data,
                      "Safe Zone Data",
                      'safeZone',
                    ),
                    _buildExportOption(
                      context,
                      data,
                      "Warning Zone Data",
                      'warningsToday',
                    ),
                    _buildExportOption(
                      context,
                      data,
                      "Danger Zone Data",
                      'dangerZones',
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Helper widget for dialog options
  Widget _buildExportOption(
    BuildContext context,
    DashboardData data,
    String title,
    String viewKey,
  ) {
    return ListTile(
      title: Text(title),
      trailing: const Icon(Icons.download),
      onTap: () {
        Navigator.pop(context); // Close dialog
        _exportData(context, data, viewKey);
      },
    );
  }

  // --- STATS GRID ---
  Widget _buildStatsGrid(BuildContext context, DashboardData data) {
    return Column(
      children: [
        Row(
          children: [
            _buildStatCard(
              context,
              data,
              "Data Received",
              data.totalReceived,
              Colors.green,
              'dataReceived',
            ),
            const SizedBox(width: 12),
            _buildStatCard(
              context,
              data,
              "Safezone",
              data.safeZone,
              Colors.green,
              'safeZone',
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildStatCard(
              context,
              data,
              "Danger Zones",
              data.dangerZones,
              Colors.red,
              'dangerZones',
            ),
            const SizedBox(width: 12),
            _buildStatCard(
              context,
              data,
              "Warnings Today",
              data.warningsToday,
              Colors.yellow,
              'warningsToday',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    DashboardData data,
    String title,
    int count,
    Color color,
    String viewKey,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          _navigateToDetail(context, data, viewKey, title, color);
        },
        child: Card(
          color: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: color, fontSize: 16)),
                const SizedBox(height: 8),
                Text(
                  count.toString().padLeft(2, '0'),
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- QUICK INSIGHTS (RADIAL BAR CHART) ---
  Widget _buildQuickInsights(BuildContext context, DashboardData data) {
    final total = data.totalReceived.toDouble();

    final dangerPercent = total > 0 ? (data.dangerZones / total) * 100 : 0.0;
    final warningPercent = total > 0 ? (data.warningsToday / total) * 100 : 0.0;
    final safePercent = total > 0 ? (data.safeZone / total) * 100 : 0.0;

    List<PieChartSectionData> sections = [
      // 1. DANGER (Red) - Reduced Radius and Opacity
      PieChartSectionData(
        value: dangerPercent,
        color: Colors.red.withOpacity(0.5), // Reduced opacity
        title: '',
        radius: 60, // Reduced radius (width)
        showTitle: false,
      ),
      // 2. WARNING (Yellow) - Medium Radius
      PieChartSectionData(
        value: warningPercent,
        color: Colors.yellow.shade700,
        title: '',
        radius: 65,
        showTitle: false,
      ),
      // 3. SAFE (Green) - Smallest Radius (Innermost)
      PieChartSectionData(
        value: safePercent,
        color: Colors.green,
        title: '',
        radius: 50,
        showTitle: false,
      ),
    ];

    return Card(
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Quick Insights",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            SizedBox(
              height: 200,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      sectionsSpace: 4,
                      centerSpaceRadius: 30,
                      startDegreeOffset: 270,
                      sections: sections,
                    ),
                  ),
                  Text(
                    '${data.totalReceived}\nTOTAL',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLegendItem(
                  Colors.red.withOpacity(0.5),
                  "Danger (${data.dangerZones})",
                ),
                _buildLegendItem(
                  Colors.yellow.shade700,
                  "Warnings (${data.warningsToday})",
                ),
                _buildLegendItem(Colors.green, "Safe Zone (${data.safeZone})"),
                const SizedBox(height: 10),
                Text(
                  "Total Readings: ${data.totalReceived}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(Icons.circle, size: 12, color: color),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  // --- MOCKED DATA LIST ---
  Widget _buildDataReceivedList(BuildContext context, DashboardData data) {
    // This mocks the dam-specific structure in the image provided
    List<Map<String, dynamic>> mockDamData = [
      {'name': 'Mettur Dam', 'tmc_filled': 72.0, 'tmc_total': 93.0},
      {'name': 'Vaigai Dam', 'tmc_filled': 54.0, 'tmc_total': 71.0},
      {'name': 'Bhavani Dam', 'tmc_filled': 30.0, 'tmc_total': 32.0},
    ];

    return Card(
      color: Theme.of(context).cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              "Status Summary (TMC)",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),

          const Divider(height: 1),

          // Header Row
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    "Name",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    "TMC",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    "Status",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Data Rows
          ...mockDamData.map((dam) {
            double percent = dam['tmc_filled'] / dam['tmc_total'];
            Color statusColor;
            if (percent > 0.95) {
              statusColor = Colors.red; // Near capacity
            } else if (percent > 0.75) {
              statusColor = Colors.yellow; // High warning
            } else {
              statusColor = Colors.green; // Normal
            }

            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Row(
                children: [
                  Expanded(flex: 3, child: Text(dam['name'])),
                  Expanded(
                    flex: 2,
                    child: Text(
                      "${dam['tmc_filled'].toStringAsFixed(1)} / ${dam['tmc_total'].toStringAsFixed(0)}",
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Icon(Icons.circle, size: 10, color: statusColor),
                  ),
                ],
              ),
            );
          }).toList(),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "Total verified river readings used for stats: ${data.readings.length}.",
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}
