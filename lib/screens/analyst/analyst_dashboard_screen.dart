import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // Chart library
import 'package:jalnetra01/common/firebase_service.dart';
import 'package:jalnetra01/models/reading_model.dart';
import 'package:jalnetra01/screens/auth/role_selection_screen.dart';
import 'package:jalnetra01/screens/common/profile_screen.dart';
import 'package:jalnetra01/screens/analyst/analyst_detail_screen.dart';
import 'package:jalnetra01/screens/common/water_level_trend_charts.dart';

// --- Constants ---
const List<String> kWaterSites = [
  'PUZHAL',
  'VEERANAM',
  'CHEMBARAMBAKAM',
  'CHOLAVARAM',
  'POONDI',
];

// --- Data Processor Class ---
class DashboardData {
  // ... (omitted for brevity, assume definition is here)
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

// --- Page Index Definition ---
enum AnalystPage { dashboard, trends, profile }

class AnalystDashboardScreen extends StatefulWidget {
  const AnalystDashboardScreen({super.key});

  @override
  State<AnalystDashboardScreen> createState() => _AnalystDashboardScreenState();
}

class _AnalystDashboardScreenState extends State<AnalystDashboardScreen> {
  static const double dangerThreshold = 4.0;
  static const double warningThreshold = 2.5;

  AnalystPage _currentPage = AnalystPage.dashboard;
  List<WaterReading> _allReadings = [];
  String _currentSiteFilter = kWaterSites.first; // NEW State for Dropdown

  // -------------------------------------------------------------------
  // DATA PROCESSING & UI LOGIC
  // -------------------------------------------------------------------

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

  // ... (omitted _navigateToDetail, assume definition is here)
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

  // ... (omitted _exportData, assume definition is here)
  void _exportData(BuildContext context, DashboardData data, String viewKey) {
    List<WaterReading> filteredList;
    String filename =
        'unknown_data'; // Initialized to prevent non-nullable error

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
  // PAGE CONTENT BUILDERS
  // -------------------------------------------------------------------

  String _getTitle() {
    switch (_currentPage) {
      case AnalystPage.dashboard:
        return 'JALNETRA - Analytics Dashboard';
      case AnalystPage.trends:
        return 'Water Level Trends';
      case AnalystPage.profile:
        return 'User Profile';
    }
  }

  Widget _getBodyWidget(DashboardData data) {
    switch (_currentPage) {
      case AnalystPage.dashboard:
        return _buildDashboardContent(data);
      case AnalystPage.trends:
        return _buildTrendsContent();
      case AnalystPage.profile:
        return const Center(
          child: Text("Use the Profile button in the drawer."),
        );
    }
  }

  Widget _buildTrendsContent() {
    if (_allReadings.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.only(top: 50.0),
          child: Text(
            'No verified readings available for trend analysis.',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // NEW: Site Selection Dropdown
          _buildSiteDropdown(),
          const SizedBox(height: 16),

          WaterLevelTrendCharts(
            allReadings: _allReadings,
            title:
                "Analyst Trend Analysis (${_allReadings.length} Total Readings)",
            selectedSite: _currentSiteFilter, // Pass the filter
          ),
        ],
      ),
    );
  }

  Widget _buildSiteDropdown() {
    return DropdownButton<String>(
      value: _currentSiteFilter,
      dropdownColor: Colors.grey.shade900,
      onChanged: (String? newValue) {
        if (newValue != null) {
          setState(() {
            _currentSiteFilter = newValue;
          });
        }
      },
      items: kWaterSites.map((String site) {
        return DropdownMenuItem<String>(
          value: site,
          child: Text(
            site,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDashboardContent(DashboardData data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. TOP STATS GRID
          _buildStatsGrid(context, data),

          const SizedBox(height: 20),

          // 2. QUICK INSIGHTS / RADIAL BAR CHART
          _buildQuickInsights(context, data),
          const SizedBox(height: 20),

          // 3. DATA RECEIVED LIST (MOCK - Now Static)
          _buildDataReceivedList(context, data),
        ],
      ),
    );
  }
  // -------------------------------------------------------------------
  // MAIN BUILD METHOD
  // -------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<WaterReading>>(
      stream: FirebaseService().getAllVerifiedReadings(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        _allReadings = snapshot.data ?? [];
        final data = _processReadings(_allReadings);

        return Scaffold(
          appBar: AppBar(
            title: Text(_getTitle()),
            actions: [
              // Logout is kept in the AppBar actions for consistent UI
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

          // --- Drawer ---
          drawer: _buildDrawer(context),

          body: _getBodyWidget(data),
        );
      },
    );
  }

  // -------------------------------------------------------------------
  // DRAWER IMPLEMENTATION
  // -------------------------------------------------------------------

  // ... (omitted _buildDrawer and _buildDrawerItem, assume definition is here)
  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Container(
        color: Theme.of(context).scaffoldBackgroundColor, // Dark background
        child: Column(
          children: <Widget>[
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Color(0xFF1E88E5), // Blue header color
              ),
              child: SizedBox(
                width: double.infinity,
                child: Text(
                  'Analyst Menu',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // Dashboard
            _buildDrawerItem(
              AnalystPage.dashboard,
              Icons.dashboard,
              'Dashboard',
            ),

            // Water Level Trends (NEW)
            _buildDrawerItem(
              AnalystPage.trends,
              Icons.show_chart,
              'Water Level Trends',
            ),

            // Profile (Moved from AppBar)
            _buildDrawerItem(AnalystPage.profile, Icons.person, 'Profile'),

            const Spacer(),
            // Separator/Footer
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                "JALNETRA v1.0",
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(AnalystPage page, IconData icon, String title) {
    final isSelected = _currentPage == page;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Theme.of(context).primaryColor : Colors.white70,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Theme.of(context).primaryColor : Colors.white,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onTap: () {
        // If profile is selected, push it (original behavior)
        if (page == AnalystPage.profile) {
          Navigator.pop(context); // Close the drawer first
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProfileScreen()),
          );
        } else {
          // Change the current page state
          setState(() {
            _currentPage = page;
          });
          Navigator.pop(context); // Close the drawer
        }
      },
    );
  }

  // --- STATS GRID ---
  Widget _buildStatsGrid(BuildContext context, DashboardData data) {
    // ... (omitted for brevity, assume definition is here)
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
    // ... (omitted for brevity, assume definition is here)
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
    // ... (omitted for brevity, assume definition is here)
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
