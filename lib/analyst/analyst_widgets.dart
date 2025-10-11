import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

// Card for AI Flood Forecast
class AIFloodForecastCard extends StatelessWidget {
  const AIFloodForecastCard({super.key});

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("AI FLOOD FORECAST", style: TextStyle(fontWeight: FontWeight.bold)),
          const Text("FLOOD LEVEL WITHIN 24HR", style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("4.75M", style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.red)
                ),
                child: const Text("IMMEDIATE DANGER", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
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
                      FlSpot(0, 3), FlSpot(1, 4), FlSpot(2, 3.5), FlSpot(3, 5),
                      FlSpot(4, 4), FlSpot(5, 6), FlSpot(6, 6.5), FlSpot(7, 6),
                    ],
                    isCurved: true,
                    color: Theme.of(context).primaryColor,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Theme.of(context).primaryColor.withOpacity(0.3),
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
  const SystemOverviewCard({super.key, required this.totalSites, required this.activeReadings});

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("SYSTEM OVERVIEW", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildStatRow("Total Sites", totalSites),
          const SizedBox(height: 8),
          _buildStatRow("Active Readings", activeReadings),
        ],
      ),
    );
  }

  Widget _buildStatRow(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(color: Colors.grey)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}


// Card for Urgent Alerts
class UrgentAlertCard extends StatelessWidget {
  final String title;
  final VoidCallback onNotify;

  const UrgentAlertCard({super.key, required this.title, required this.onNotify});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE57373).withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE57373)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text("URGENT ALERTS", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFE57373))),
          const SizedBox(height: 8),
          Text(title),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onNotify,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF44336)),
            child: const Text("NOTIFY NDMA"),
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
          const Text("DATA TRENDS", style: TextStyle(fontWeight: FontWeight.bold)),
          const Text("Daily Rainfall (mm)", style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 20),
          SizedBox(
            height: 100,
            child: LineChart(
               LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey.withOpacity(0.5))),
                 lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 10), FlSpot(1, 20), FlSpot(2, 15), FlSpot(3, 30),
                      FlSpot(4, 25), FlSpot(5, 40),
                    ],
                    isCurved: true,
                    color: Colors.blueAccent,
                  ),
                ],
              )
            ),
          )
        ],
      ),
    );
  }
}

// Card for Data Audit
class DataAuditCard extends StatelessWidget {
  final int pendingSubmissions;
  final VoidCallback onReview;

  const DataAuditCard({super.key, required this.pendingSubmissions, required this.onReview});

  @override
  Widget build(BuildContext context) {
    return DashboardCard(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("COMMUNITY & DATA AUDIT", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Pending Submissions"),
            Text("$pendingSubmissions", style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(onPressed: onReview, child: const Text("REVIEW")))
      ],
    ));
  }
}

// Card for Report Generator
class CustomReportCard extends StatelessWidget {
  final VoidCallback onGenerate;

  const CustomReportCard({super.key, required this.onGenerate});

  @override
  Widget build(BuildContext context) {
     return DashboardCard(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("CUSTOM REPORT GENERATOR", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        const TextField(decoration: InputDecoration(labelText: "River Basin")),
        const SizedBox(height: 10),
        const TextField(decoration: InputDecoration(labelText: "Time Period")),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(onPressed: onGenerate, child: const Text("GENERATE REPORT")))
      ],
    ));
  }
}


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
        borderRadius: BorderRadius.circular(8),
      ),
      child: child,
    );
  }
}