import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

void main() {
  runApp(const JalnetraDashboard());
}

class JalnetraDashboard extends StatelessWidget {
  const JalnetraDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JALNETRA Analyst Dashboard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
      ),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                "JALNETRA ANALYST DASHBOARD",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 24),

              // AI Flood Forecast Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // AI FLOOD FORECAST Header
                    const Text(
                      "AI FLOOD FORECAST",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.redAccent,
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 2, bottom: 8),
                      height: 2,
                      color: Colors.yellow,
                      width: width * 0.6,
                    ),

                    const Text(
                      "FLOOD LEVEL WITHIN 24HRS",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        letterSpacing: 1,
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Flood Level
                    const Text(
                      "4.75 M",
                      style: TextStyle(
                        fontSize: 42,
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 2, bottom: 12),
                      height: 2,
                      color: Colors.yellow,
                      width: width * 0.25,
                    ),

                    // Immediate Danger Label
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        "IMMEDIATE DANGER",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 1.5,
                          decoration: TextDecoration.underline,
                          decorationColor: Colors.yellow,
                          decorationThickness: 2,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Animated Wave Graph
                    SizedBox(
                      height: 120,
                      child: LineChart(
                        LineChartData(
                          gridData: const FlGridData(show: false),
                          titlesData: const FlTitlesData(show: false),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            LineChartBarData(
                              isCurved: true,
                              color: Colors.tealAccent,
                              barWidth: 3,
                              belowBarData: BarAreaData(
                                show: true,
                                color:
                                    Colors.tealAccent.withOpacity(0.2),
                              ),
                              spots: const [
                                FlSpot(0, 1),
                                FlSpot(1, 1.2),
                                FlSpot(2, 0.8),
                                FlSpot(3, 1.4),
                                FlSpot(4, 1.1),
                                FlSpot(5, 1.3),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // System Overview
              _buildCard(
                title: "System Overview",
                subtitle:
                    "All monitoring systems operational. 5 active sensors online.",
              ),

              const SizedBox(height: 16),

              // Urgent Alerts
              _buildCard(
                title: "Urgent Alerts",
                subtitle:
                    "⚠️ Zone 3: Rapid water rise detected.\n⚠️ Zone 5: Sensor threshold exceeded.",
                titleColor: Colors.redAccent,
              ),

              const SizedBox(height: 16),

              // Map Placeholder
              _buildCard(
                title: "Live Network Map",
                subtitle: "Map integration coming soon...",
              ),

              const SizedBox(height: 16),

              // Statistics
              _buildCard(
                title: "Flood Data Statistics",
                subtitle: "Visualization for rainfall and sensor data coming soon.",
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // Reusable card builder
  Widget _buildCard({
    required String title,
    required String subtitle,
    Color titleColor = Colors.white,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
