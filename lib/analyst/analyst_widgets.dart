// lib/analyst/analyst_widgets.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

// Base card widget for consistent styling
class DashboardCard extends StatelessWidget {
  final Widget child;
  const DashboardCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}

// Card for AI Flood Forecast
class AIFloodForecastCard extends StatelessWidget {
  const AIFloodForecastCard({super.key});

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "AI FLOOD FORECAST",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          const Text(
            "FLOOD LEVEL WITHIN 24HR",
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "4.75M",
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.redAccent),
                ),
                child: const Text(
                  "IMMEDIATE DANGER",
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 120,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 3),
                      FlSpot(1, 4),
                      FlSpot(2, 3.5),
                      FlSpot(3, 5),
                      FlSpot(4, 4),
                      FlSpot(5, 6),
                      FlSpot(6, 6.5),
                      FlSpot(7, 6),
                    ],
                    isCurved: true,
                    color: Colors.tealAccent,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.tealAccent.withOpacity(0.3),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Card for System Overview
class SystemOverviewCard extends StatelessWidget {
  final String totalSites;
  final String activeReadings;
  const SystemOverviewCard({
    super.key,
    required this.totalSites,
    required this.activeReadings,
  });

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "SYSTEM OVERVIEW",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 16),
          _buildStatRow("Total Sites", totalSites, Colors.white),
          const SizedBox(height: 8),
          _buildStatRow(
            "Active Readings (Last 24h)",
            activeReadings,
            Theme.of(context).primaryColor,
          ),
          const SizedBox(height: 8),
          _buildStatRow("Offline Sites", "5", Colors.redAccent),
        ],
      ),
    );
  }

  Widget _buildStatRow(String title, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(color: Colors.grey)),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.bold, color: valueColor),
        ),
      ],
    );
  }
}

// Card for Urgent Alerts
class UrgentAlertCard extends StatelessWidget {
  final String title;
  final VoidCallback onNotify;

  const UrgentAlertCard({
    super.key,
    required this.title,
    required this.onNotify,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE57373).withOpacity(0.1), // Lighter background
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE57373)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            "URGENT ALERTS",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFFE57373),
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onNotify,
            icon: const Icon(Icons.flash_on),
            label: const Text(
              "NOTIFY NDMA",
            ), // Fixed: Added required 'label' parameter
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF44336),
            ),
          ),
        ],
      ),
    );
  }
}

// Card for Data Trends
class DataTrendsCard extends StatelessWidget {
  const DataTrendsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "DATA TRENDS",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const Text(
            "Daily Rainfall (mm) vs. Water Level",
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 150,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 10,
                  checkToShowHorizontalLine: (value) => value % 10 == 0,
                ),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.grey.withOpacity(0.5)),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 10),
                      FlSpot(1, 20),
                      FlSpot(2, 15),
                      FlSpot(3, 30),
                      FlSpot(4, 25),
                      FlSpot(5, 40),
                    ],
                    isCurved: true,
                    color: Colors.blueAccent,
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                  ),
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 25),
                      FlSpot(1, 28),
                      FlSpot(2, 26),
                      FlSpot(3, 35),
                      FlSpot(4, 32),
                      FlSpot(5, 45),
                    ],
                    isCurved: true,
                    color: Theme.of(context).primaryColor,
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegend(Colors.blueAccent, "Rainfall (mm)"),
              const SizedBox(width: 15),
              _buildLegend(Theme.of(context).primaryColor, "Water Level (cm)"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(Color color, String label) {
    return Row(
      children: [
        Container(width: 10, height: 10, color: color),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}

// Card for Data Audit
class DataAuditCard extends StatelessWidget {
  final int pendingSubmissions;
  final VoidCallback onReview;

  const DataAuditCard({
    super.key,
    required this.pendingSubmissions,
    required this.onReview,
  });

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "COMMUNITY & DATA AUDIT",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Pending Public Submissions"),
              Text(
                "$pendingSubmissions",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              // Fixed: Changed from ElevatedButton to ElevatedButton.icon if icon is used
              onPressed: onReview,
              icon: const Icon(Icons.rate_review),
              label: const Text(
                "REVIEW AUDIT QUEUE",
              ), // Fixed: Added required 'label' parameter
            ),
          ),
        ],
      ),
    );
  }
}

// Card for Report Generator
class CustomReportCard extends StatelessWidget {
  final VoidCallback onGenerate;

  const CustomReportCard({super.key, required this.onGenerate});

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "CUSTOM REPORT GENERATOR",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 16),
          const TextField(
            decoration: InputDecoration(labelText: "River Basin/Site ID"),
          ),
          const SizedBox(height: 10),
          const TextField(
            decoration: InputDecoration(
              labelText: "Time Period (e.g., Last 30 Days)",
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              // Fixed: Changed from ElevatedButton to ElevatedButton.icon if icon is used
              onPressed: onGenerate,
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text(
                "GENERATE REPORT",
              ), // Fixed: Added required 'label' parameter
            ),
          ),
        ],
      ),
    );
  }
}
