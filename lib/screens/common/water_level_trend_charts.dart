import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:jalnetra01/models/reading_model.dart';

class WaterLevelTrendCharts extends StatelessWidget {
  final List<WaterReading> allReadings;
  final String title;
  final String selectedSite;

  const WaterLevelTrendCharts({
    super.key,
    required this.allReadings,
    required this.title,
    required this.selectedSite,
  });

  // Helper to filter readings by the selected site
  List<WaterReading> _getSiteReadings() {
    return allReadings.where((reading) {
      // Mock filter logic – adjust to your real model field (e.g., reading.siteId)
      return selectedSite == 'PUZHAL' || reading.id.contains(selectedSite);
    }).toList();
  }

  // --- SITE-SPECIFIC MOCK DATA GENERATION ---

  List<FlSpot> _generateWeeklyData() {
    // You can later compute real averages from _getSiteReadings()
    final double base = selectedSite.length.toDouble() * 0.3;

    return [
      FlSpot(1, (4.5 + base).clamp(1.0, 10.0)),
      FlSpot(2, (4.2 + base * 0.9).clamp(1.0, 10.0)),
      FlSpot(3, (4.0 + base * 0.8).clamp(1.0, 10.0)),
      FlSpot(4, (3.8 + base * 0.7).clamp(1.0, 10.0)),
      FlSpot(5, (3.5 + base * 0.6).clamp(1.0, 10.0)),
      FlSpot(6, (3.7 + base * 0.5).clamp(1.0, 10.0)),
      FlSpot(7, (3.9 + base * 0.4).clamp(1.0, 10.0)),
    ];
  }

  List<BarChartGroupData> _generateMonthlyData() {
    final double avgAdjustment = selectedSite.length.toDouble() * 0.4;

    return List.generate(4, (index) {
      final weekAvg = 3.0 + (index * 0.7) + avgAdjustment;
      final double clamped = weekAvg.clamp(0.0, 10.0);

      Color barColor;
      if (clamped >= 8.0) {
        barColor = Colors.red;
      } else if (clamped >= 5.0) {
        barColor = Colors.orangeAccent;
      } else {
        barColor = Colors.green;
      }

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: clamped,
            color: barColor,
            width: 15,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(6),
            ),
          ),
        ],
      );
    });
  }

  // ----------------------------

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white70 : Colors.black87;
    final Color cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Card(
      elevation: 4,
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.blueAccent : Colors.blue.shade800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Viewing trends for: $selectedSite",
              style: TextStyle(fontSize: 14, color: textColor.withOpacity(0.7)),
            ),
            Divider(color: textColor.withOpacity(0.5)),

            // --- Weekly Trend Chart (Line) ---
            Text(
              "Water Level Trend (Last 7 Days)",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 15),
            SizedBox(height: 220, child: _buildWeeklyLineChart(textColor)),

            const SizedBox(height: 25),

            // --- Monthly Summary Chart (Bar) ---
            Text(
              "Monthly Average Water Level Summary (Per Week)",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 15),
            SizedBox(height: 220, child: _buildMonthlyBarChart(textColor)),
          ],
        ),
      ),
    );
  }

  // ───────────────── WEEKLY LINE CHART ─────────────────

  Widget _buildWeeklyLineChart(Color textColor) {
    final Color primaryColor = Colors.cyanAccent.shade400;

    return LineChart(
      LineChartData(
        minX: 1,
        maxX: 7,
        minY: 0,
        maxY: 10, // 0–10, label 2,4,6,8,10
        backgroundColor: Colors.transparent,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) => spots
                .map(
                  (spot) => LineTooltipItem(
                    'Day ${spot.x.toInt()}: ${spot.y.toStringAsFixed(2)}m',
                    TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
                  ),
                )
                .toList(),
          ),
        ),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),

          // Y-Axis Titles (Left)
          leftTitles: AxisTitles(
            axisNameWidget: Text(
              "Level (m)",
              style: TextStyle(color: textColor.withOpacity(0.9), fontSize: 12),
            ),
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: 2, // 0,2,4,6,8,10
              getTitlesWidget: (double value, TitleMeta meta) {
                if (value == 0) {
                  return const SizedBox.shrink(); // hide 0 → show 2,4,6,8,10
                }
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(
                    color: textColor.withOpacity(0.8),
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),

          // X-Axis Titles (Bottom)
          bottomTitles: AxisTitles(
            axisNameWidget: Text(
              "Day of Week",
              style: TextStyle(color: textColor.withOpacity(0.9), fontSize: 12),
            ),
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (double value, TitleMeta meta) {
                return SideTitleWidget(
                  meta: meta, // correct API
                  space: 8,
                  child: Text(
                    'Day ${value.toInt()}',
                    style: TextStyle(
                      color: textColor.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 2,
          getDrawingHorizontalLine: (value) =>
              FlLine(color: textColor.withOpacity(0.15), strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: _generateWeeklyData(),
            isCurved: true,
            color: primaryColor,
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: primaryColor,
                  strokeColor: Colors.black,
                  strokeWidth: 1.5,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  primaryColor.withOpacity(0.4),
                  primaryColor.withOpacity(0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────── MONTHLY BAR CHART ─────────────────

  Widget _buildMonthlyBarChart(Color textColor) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 10.0,
        minY: 0,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                'Wk ${group.x + 1}: ${rod.toY.toStringAsFixed(2)}m',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
        barGroups: _generateMonthlyData(),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),

          // Y Axis
          leftTitles: AxisTitles(
            axisNameWidget: Text(
              "Level (m)",
              style: TextStyle(color: textColor.withOpacity(0.9), fontSize: 12),
            ),
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: 2, // 0,2,4,6,8,10
              getTitlesWidget: (double value, TitleMeta meta) {
                if (value == 0) {
                  return const SizedBox.shrink(); // hide 0, show 2,4,6,8,10
                }
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(
                    color: textColor.withOpacity(0.8),
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),

          // X Axis
          bottomTitles: AxisTitles(
            axisNameWidget: Text(
              "Week of Month",
              style: TextStyle(color: textColor.withOpacity(0.9), fontSize: 12),
            ),
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (double value, TitleMeta meta) {
                return SideTitleWidget(
                  meta: meta,
                  space: 8,
                  child: Text(
                    'Wk ${value.toInt() + 1}',
                    style: TextStyle(
                      color: textColor.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) =>
              FlLine(color: textColor.withOpacity(0.15), strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
      ),
    );
  }
}
