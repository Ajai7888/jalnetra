import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class AnalystDashboardScreen extends StatefulWidget {
  const AnalystDashboardScreen({super.key});

  @override
  State<AnalystDashboardScreen> createState() => _AnalystDashboardScreenState();
}

class _AnalystDashboardScreenState extends State<AnalystDashboardScreen> {
  String _selectedSite = 'all';

  @override
  Widget build(BuildContext context) {
    // Local dark theme just for this screen
    final darkTheme = ThemeData.dark().copyWith(
      scaffoldBackgroundColor: Colors.transparent,
      cardColor: const Color(0xff111827),
      textTheme: ThemeData.dark().textTheme.apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
    );

    return Theme(
      data: darkTheme,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xff020617), Color(0xff111827)], // near-black
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('readings')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          CircularProgressIndicator(),
                          SizedBox(height: 12),
                          Text('Loading Dashboard...'),
                        ],
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error loading data: ${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  final docs = snapshot.data?.docs ?? [];
                  final readings = docs.map((d) => Reading.fromDoc(d)).toList();

                  if (readings.isEmpty) {
                    return const Center(
                      child: Text('No readings found in Firestore.'),
                    );
                  }

                  final sites =
                      readings
                          .map((r) => r.siteId)
                          .where((s) => s.isNotEmpty)
                          .toSet()
                          .toList()
                        ..sort();

                  final String? selectedSiteData = _selectedSite != 'all'
                      ? _selectedSite
                      : (sites.isNotEmpty ? sites.first : null);

                  final manualVsAuto = getManualVsAutomated(readings);
                  final verificationStats = getVerificationStats(readings);
                  final siteReadCounts = getSiteReadingsCount(readings);
                  final weeklyTrend = getWeeklyTrend(readings, _selectedSite);
                  final highestSites = getHighestWaterLevelSite(readings);
                  final now = DateTime.now();

                  final lastHourCount = getReadingsByTimeRange(
                    readings,
                    _selectedSite,
                    1,
                  );
                  final last24Count = getReadingsByTimeRange(
                    readings,
                    _selectedSite,
                    24,
                  );
                  final lastWeekCount = getReadingsByTimeRange(
                    readings,
                    _selectedSite,
                    168,
                  );

                  final todayLevels = selectedSiteData != null
                      ? getTodayWaterLevels(readings, selectedSiteData)
                      : <TimePeriodLevel>[];

                  final waterChange = selectedSiteData != null
                      ? getWaterLevelChange(readings, selectedSiteData)
                      : const WaterChange.zero();

                  return Column(
                    children: [
                      _Header(
                        sites: sites,
                        selectedSite: _selectedSite,
                        onSiteChanged: (value) {
                          setState(() {
                            _selectedSite = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              _KeyMetricsRow(
                                lastHourCount: lastHourCount,
                                last24Count: last24Count,
                                lastWeekCount: lastWeekCount,
                                totalSites: sites.length,
                              ),
                              const SizedBox(height: 16),

                              // Row 1
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final isWide = constraints.maxWidth > 800;
                                  return Flex(
                                    direction: isWide
                                        ? Axis.horizontal
                                        : Axis.vertical,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Flexible(
                                        flex: 1,
                                        child: _CardContainer(
                                          title: 'Manual vs Automated Readings',
                                          child: Column(
                                            children: [
                                              SizedBox(
                                                height: 240,
                                                child: PieChart(
                                                  PieChartData(
                                                    sectionsSpace: 4,
                                                    centerSpaceRadius: 40,
                                                    sections: manualVsAuto
                                                        .map(
                                                          (
                                                            d,
                                                          ) => PieChartSectionData(
                                                            color: d.color,
                                                            value: d.value
                                                                .toDouble(),
                                                            title:
                                                                '${d.name}\n${d.value.toInt()}',
                                                            radius: 70,
                                                            titleStyle:
                                                                const TextStyle(
                                                                  fontSize: 12,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  color: Colors
                                                                      .white,
                                                                ),
                                                          ),
                                                        )
                                                        .toList(),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                              Container(
                                                width: double.infinity,
                                                padding: const EdgeInsets.all(
                                                  12,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xff1d4ed8,
                                                  ).withOpacity(0.25),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  _manualAutoInsight(
                                                    manualVsAuto,
                                                  ),
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.white70,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      if (isWide)
                                        const SizedBox(width: 16)
                                      else
                                        const SizedBox(height: 16),
                                      Flexible(
                                        flex: 1,
                                        child: _CardContainer(
                                          title: 'Readings per Site',
                                          child: Column(
                                            children: [
                                              SizedBox(
                                                height: 240,
                                                child: BarChart(
                                                  BarChartData(
                                                    gridData: FlGridData(
                                                      show: true,
                                                      drawVerticalLine: false,
                                                      horizontalInterval: 5,
                                                      getDrawingHorizontalLine:
                                                          (value) => FlLine(
                                                            color:
                                                                Colors.white12,
                                                            strokeWidth: 1,
                                                          ),
                                                    ),
                                                    borderData: FlBorderData(
                                                      show: false,
                                                    ),
                                                    titlesData: FlTitlesData(
                                                      bottomTitles: AxisTitles(
                                                        sideTitles: SideTitles(
                                                          showTitles: true,
                                                          getTitlesWidget: (value, meta) {
                                                            final index = value
                                                                .toInt();
                                                            if (index < 0 ||
                                                                index >=
                                                                    siteReadCounts
                                                                        .length) {
                                                              return const SizedBox.shrink();
                                                            }
                                                            return Padding(
                                                              padding:
                                                                  const EdgeInsets.only(
                                                                    top: 4,
                                                                  ),
                                                              child: Text(
                                                                siteReadCounts[index]
                                                                    .site,
                                                                style: const TextStyle(
                                                                  fontSize: 10,
                                                                  color: Colors
                                                                      .white70,
                                                                ),
                                                              ),
                                                            );
                                                          },
                                                        ),
                                                      ),
                                                      leftTitles: AxisTitles(
                                                        sideTitles: SideTitles(
                                                          showTitles: true,
                                                          reservedSize: 30,
                                                          getTitlesWidget:
                                                              (value, meta) {
                                                                return Text(
                                                                  value
                                                                      .toInt()
                                                                      .toString(),
                                                                  style: const TextStyle(
                                                                    fontSize:
                                                                        10,
                                                                    color: Colors
                                                                        .white60,
                                                                  ),
                                                                );
                                                              },
                                                        ),
                                                      ),
                                                    ),
                                                    barGroups: List.generate(
                                                      siteReadCounts.length,
                                                      (index) {
                                                        final item =
                                                            siteReadCounts[index];
                                                        return BarChartGroupData(
                                                          x: index,
                                                          barRods: [
                                                            BarChartRodData(
                                                              toY: item.count
                                                                  .toDouble(),
                                                              width: 18,
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    4,
                                                                  ),
                                                              // color handled by theme / default
                                                            ),
                                                          ],
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                              Container(
                                                width: double.infinity,
                                                padding: const EdgeInsets.all(
                                                  12,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xff15803d,
                                                  ).withOpacity(0.25),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  _siteReadingsInsight(
                                                    siteReadCounts,
                                                  ),
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.white70,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),

                              const SizedBox(height: 16),

                              // Row 2
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final isWide = constraints.maxWidth > 800;
                                  return Flex(
                                    direction: isWide
                                        ? Axis.horizontal
                                        : Axis.vertical,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Flexible(
                                        flex: 1,
                                        child: _CardContainer(
                                          title:
                                              "Today's Water Levels - ${selectedSiteData ?? 'N/A'}",
                                          child: Column(
                                            children: [
                                              SizedBox(
                                                height: 240,
                                                child: BarChart(
                                                  BarChartData(
                                                    gridData: FlGridData(
                                                      show: true,
                                                      drawVerticalLine: false,
                                                      horizontalInterval: 1,
                                                      getDrawingHorizontalLine:
                                                          (value) => FlLine(
                                                            color:
                                                                Colors.white12,
                                                            strokeWidth: 1,
                                                          ),
                                                    ),
                                                    borderData: FlBorderData(
                                                      show: false,
                                                    ),
                                                    titlesData: FlTitlesData(
                                                      bottomTitles: AxisTitles(
                                                        sideTitles: SideTitles(
                                                          showTitles: true,
                                                          getTitlesWidget: (value, meta) {
                                                            final idx = value
                                                                .toInt();
                                                            if (idx < 0 ||
                                                                idx >=
                                                                    todayLevels
                                                                        .length) {
                                                              return const SizedBox.shrink();
                                                            }
                                                            return Padding(
                                                              padding:
                                                                  const EdgeInsets.only(
                                                                    top: 4,
                                                                  ),
                                                              child: Text(
                                                                todayLevels[idx]
                                                                    .period,
                                                                style: const TextStyle(
                                                                  fontSize: 11,
                                                                  color: Colors
                                                                      .white70,
                                                                ),
                                                              ),
                                                            );
                                                          },
                                                        ),
                                                      ),
                                                      leftTitles: AxisTitles(
                                                        sideTitles: SideTitles(
                                                          showTitles: true,
                                                          reservedSize: 30,
                                                          getTitlesWidget: (value, meta) {
                                                            return Text(
                                                              value
                                                                  .toStringAsFixed(
                                                                    0,
                                                                  ),
                                                              style:
                                                                  const TextStyle(
                                                                    fontSize:
                                                                        10,
                                                                    color: Colors
                                                                        .white60,
                                                                  ),
                                                            );
                                                          },
                                                        ),
                                                      ),
                                                    ),
                                                    barGroups: List.generate(
                                                      todayLevels.length,
                                                      (index) {
                                                        final item =
                                                            todayLevels[index];
                                                        return BarChartGroupData(
                                                          x: index,
                                                          barRods: [
                                                            BarChartRodData(
                                                              toY: item.level,
                                                              width: 18,
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    4,
                                                                  ),
                                                            ),
                                                          ],
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                              Container(
                                                width: double.infinity,
                                                padding: const EdgeInsets.all(
                                                  12,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xfffacc15,
                                                  ).withOpacity(0.18),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      waterChange.trend ==
                                                              Trend.up
                                                          ? Icons.trending_up
                                                          : waterChange.trend ==
                                                                Trend.down
                                                          ? Icons.trending_down
                                                          : Icons
                                                                .horizontal_rule,
                                                      color:
                                                          waterChange.trend ==
                                                              Trend.up
                                                          ? Colors.redAccent
                                                          : waterChange.trend ==
                                                                Trend.down
                                                          ? Colors.greenAccent
                                                          : Colors.white60,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Text(
                                                        _waterChangeText(
                                                          waterChange,
                                                        ),
                                                        style: const TextStyle(
                                                          fontSize: 13,
                                                          color: Colors.white70,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      if (isWide)
                                        const SizedBox(width: 16)
                                      else
                                        const SizedBox(height: 16),
                                      Flexible(
                                        flex: 1,
                                        child: _CardContainer(
                                          title:
                                              'Weekly Water Level Trend - ${_selectedSite == 'all' ? 'All Sites' : _selectedSite}',
                                          child: Column(
                                            children: [
                                              SizedBox(
                                                height: 240,
                                                child: LineChart(
                                                  LineChartData(
                                                    gridData: FlGridData(
                                                      show: true,
                                                      drawVerticalLine: false,
                                                      horizontalInterval: 1,
                                                      getDrawingHorizontalLine:
                                                          (value) => FlLine(
                                                            color:
                                                                Colors.white12,
                                                            strokeWidth: 1,
                                                          ),
                                                    ),
                                                    titlesData: FlTitlesData(
                                                      bottomTitles: AxisTitles(
                                                        sideTitles: SideTitles(
                                                          showTitles: true,
                                                          getTitlesWidget: (value, meta) {
                                                            final idx = value
                                                                .toInt();
                                                            if (idx < 0 ||
                                                                idx >=
                                                                    weeklyTrend
                                                                        .length) {
                                                              return const SizedBox.shrink();
                                                            }
                                                            return Padding(
                                                              padding:
                                                                  const EdgeInsets.only(
                                                                    top: 4,
                                                                  ),
                                                              child: Text(
                                                                weeklyTrend[idx]
                                                                    .day,
                                                                style: const TextStyle(
                                                                  fontSize: 11,
                                                                  color: Colors
                                                                      .white70,
                                                                ),
                                                              ),
                                                            );
                                                          },
                                                        ),
                                                      ),
                                                      leftTitles: AxisTitles(
                                                        sideTitles: SideTitles(
                                                          showTitles: true,
                                                          reservedSize: 30,
                                                          getTitlesWidget: (value, meta) {
                                                            return Text(
                                                              value
                                                                  .toStringAsFixed(
                                                                    0,
                                                                  ),
                                                              style:
                                                                  const TextStyle(
                                                                    fontSize:
                                                                        10,
                                                                    color: Colors
                                                                        .white60,
                                                                  ),
                                                            );
                                                          },
                                                        ),
                                                      ),
                                                    ),
                                                    borderData: FlBorderData(
                                                      show: false,
                                                    ),
                                                    lineBarsData: [
                                                      LineChartBarData(
                                                        isCurved: true,
                                                        dotData: FlDotData(
                                                          show: true,
                                                        ),
                                                        barWidth: 3,
                                                        spots: List.generate(
                                                          weeklyTrend.length,
                                                          (index) {
                                                            final item =
                                                                weeklyTrend[index];
                                                            return FlSpot(
                                                              index.toDouble(),
                                                              item.level,
                                                            );
                                                          },
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                              Container(
                                                width: double.infinity,
                                                padding: const EdgeInsets.all(
                                                  12,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xffa855f7,
                                                  ).withOpacity(0.2),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  _weeklyTrendInsight(
                                                    weeklyTrend,
                                                  ),
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.white70,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),

                              const SizedBox(height: 16),

                              // Row 3
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final isWide = constraints.maxWidth > 800;
                                  return Flex(
                                    direction: isWide
                                        ? Axis.horizontal
                                        : Axis.vertical,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Flexible(
                                        flex: 1,
                                        child: _CardContainer(
                                          title:
                                              'Highest Water Levels This Week',
                                          child: Column(
                                            children: [
                                              SizedBox(
                                                height: 240,
                                                child: BarChart(
                                                  BarChartData(
                                                    gridData: FlGridData(
                                                      show: true,
                                                      drawVerticalLine: false,
                                                      horizontalInterval: 1,
                                                      getDrawingHorizontalLine:
                                                          (value) => FlLine(
                                                            color:
                                                                Colors.white12,
                                                            strokeWidth: 1,
                                                          ),
                                                    ),
                                                    borderData: FlBorderData(
                                                      show: false,
                                                    ),
                                                    titlesData: FlTitlesData(
                                                      bottomTitles: AxisTitles(
                                                        sideTitles: SideTitles(
                                                          showTitles: true,
                                                          getTitlesWidget: (value, meta) {
                                                            final idx = value
                                                                .toInt();
                                                            if (idx < 0 ||
                                                                idx >=
                                                                    highestSites
                                                                        .length) {
                                                              return const SizedBox.shrink();
                                                            }
                                                            return Padding(
                                                              padding:
                                                                  const EdgeInsets.only(
                                                                    top: 4,
                                                                  ),
                                                              child: Text(
                                                                highestSites[idx]
                                                                    .site,
                                                                style: const TextStyle(
                                                                  fontSize: 11,
                                                                  color: Colors
                                                                      .white70,
                                                                ),
                                                              ),
                                                            );
                                                          },
                                                        ),
                                                      ),
                                                      leftTitles: AxisTitles(
                                                        sideTitles: SideTitles(
                                                          showTitles: true,
                                                          reservedSize: 30,
                                                          getTitlesWidget: (value, meta) {
                                                            return Text(
                                                              value
                                                                  .toStringAsFixed(
                                                                    0,
                                                                  ),
                                                              style:
                                                                  const TextStyle(
                                                                    fontSize:
                                                                        10,
                                                                    color: Colors
                                                                        .white60,
                                                                  ),
                                                            );
                                                          },
                                                        ),
                                                      ),
                                                    ),
                                                    barGroups: List.generate(
                                                      highestSites.length,
                                                      (index) {
                                                        final item =
                                                            highestSites[index];
                                                        return BarChartGroupData(
                                                          x: index,
                                                          barRods: [
                                                            BarChartRodData(
                                                              toY:
                                                                  item.avgLevel,
                                                              width: 18,
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    4,
                                                                  ),
                                                            ),
                                                          ],
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                              Container(
                                                width: double.infinity,
                                                padding: const EdgeInsets.all(
                                                  12,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xffef4444,
                                                  ).withOpacity(0.2),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  _highestSiteInsight(
                                                    highestSites,
                                                  ),
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.white70,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      if (isWide)
                                        const SizedBox(width: 16)
                                      else
                                        const SizedBox(height: 16),
                                      Flexible(
                                        flex: 1,
                                        child: _CardContainer(
                                          title: 'Verification Status',
                                          child: Column(
                                            children: [
                                              SizedBox(
                                                height: 240,
                                                child: PieChart(
                                                  PieChartData(
                                                    sectionsSpace: 4,
                                                    centerSpaceRadius: 40,
                                                    sections: verificationStats
                                                        .map(
                                                          (
                                                            d,
                                                          ) => PieChartSectionData(
                                                            color: d.color,
                                                            value: d.value
                                                                .toDouble(),
                                                            title:
                                                                '${d.name}\n${d.value.toInt()}',
                                                            radius: 70,
                                                            titleStyle:
                                                                const TextStyle(
                                                                  fontSize: 12,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  color: Colors
                                                                      .white,
                                                                ),
                                                          ),
                                                        )
                                                        .toList(),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                              Container(
                                                width: double.infinity,
                                                padding: const EdgeInsets.all(
                                                  12,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xfff97316,
                                                  ).withOpacity(0.18),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      verificationStats.length >
                                                                  1 &&
                                                              verificationStats[1]
                                                                      .value >
                                                                  0
                                                          ? Icons.warning_amber
                                                          : Icons.check_circle,
                                                      color:
                                                          verificationStats
                                                                      .length >
                                                                  1 &&
                                                              verificationStats[1]
                                                                      .value >
                                                                  0
                                                          ? Colors.orangeAccent
                                                          : Colors.greenAccent,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Text(
                                                        _verificationInsight(
                                                          verificationStats,
                                                        ),
                                                        style: const TextStyle(
                                                          fontSize: 13,
                                                          color: Colors.white70,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),

                              const SizedBox(height: 16),

                              _CardContainer(
                                title: 'Summary',
                                child: Align(
                                  alignment: Alignment.center,
                                  child: Text(
                                    'Last updated: ${DateFormat('dd MMM yyyy, hh:mm a').format(now)} | '
                                    'Total Readings: ${readings.length}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// HEADER

class _Header extends StatelessWidget {
  final List<String> sites;
  final String selectedSite;
  final ValueChanged<String> onSiteChanged;

  const _Header({
    required this.sites,
    required this.selectedSite,
    required this.onSiteChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _CardContainer(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.water_drop, color: Colors.lightBlueAccent, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Water Level Monitoring Dashboard',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Real-time analytics and insights',
                  style: TextStyle(fontSize: 13, color: Colors.white60),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          DropdownButton<String>(
            value: selectedSite,
            dropdownColor: const Color(0xff020617),
            borderRadius: BorderRadius.circular(12),
            style: const TextStyle(color: Colors.white),
            items: [
              const DropdownMenuItem(value: 'all', child: Text('All Sites')),
              ...sites.map((s) => DropdownMenuItem(value: s, child: Text(s))),
            ],
            onChanged: (v) {
              if (v != null) onSiteChanged(v);
            },
          ),
        ],
      ),
    );
  }
}

/// CARD CONTAINER

class _CardContainer extends StatelessWidget {
  final String? title;
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _CardContainer({
    this.title,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = Theme.of(context).cardColor;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Text(
                title!,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
            ],
            child,
          ],
        ),
      ),
    );
  }
}

/// KEY METRICS

class _KeyMetricsRow extends StatelessWidget {
  final int lastHourCount;
  final int last24Count;
  final int lastWeekCount;
  final int totalSites;

  const _KeyMetricsRow({
    required this.lastHourCount,
    required this.last24Count,
    required this.lastWeekCount,
    required this.totalSites,
  });

  @override
  Widget build(BuildContext context) {
    final cards = [
      _MetricCard(
        label: 'Last Hour',
        value: lastHourCount.toString(),
        icon: Icons.schedule,
        color: Colors.lightBlueAccent,
      ),
      _MetricCard(
        label: 'Last 24 Hours',
        value: last24Count.toString(),
        icon: Icons.bolt,
        color: Colors.greenAccent,
      ),
      _MetricCard(
        label: 'Last Week',
        value: lastWeekCount.toString(),
        icon: Icons.map,
        color: Colors.deepPurpleAccent,
      ),
      _MetricCard(
        label: 'Total Sites',
        value: totalSites.toString(),
        icon: Icons.filter_alt,
        color: Colors.orangeAccent,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 800;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isWide ? 4 : 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 100,
          ),
          itemBuilder: (context, index) => cards[index],
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return _CardContainer(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Colors.white60),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

//
// ---------- DATA MODEL & ANALYTICS (same as before) ----------
//

class Reading {
  final String id;
  final String siteId;
  final double waterLevel;
  final bool isManual;
  final bool isVerified;
  final DateTime timestamp;
  final String officerId;

  Reading({
    required this.id,
    required this.siteId,
    required this.waterLevel,
    required this.isManual,
    required this.isVerified,
    required this.timestamp,
    required this.officerId,
  });

  factory Reading.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final ts = data['timestamp'];
    DateTime dateTime;

    if (ts is Timestamp) {
      dateTime = ts.toDate();
    } else if (ts is DateTime) {
      dateTime = ts;
    } else if (ts is String) {
      dateTime = DateTime.tryParse(ts) ?? DateTime.now();
    } else {
      dateTime = DateTime.now();
    }

    return Reading(
      id: doc.id,
      siteId: (data['siteId'] ?? '') as String,
      waterLevel: (data['waterLevel'] as num?)?.toDouble() ?? 0.0,
      isManual: (data['isManual'] as bool?) ?? false,
      isVerified: (data['isVerified'] as bool?) ?? false,
      timestamp: dateTime,
      officerId: (data['officerId'] ?? '') as String,
    );
  }
}

class PieStat {
  final String name;
  final double value;
  final Color color;

  PieStat(this.name, this.value, this.color);
}

class SiteCount {
  final String site;
  final int count;

  SiteCount(this.site, this.count);
}

class DayTrend {
  final String day;
  final double level;
  final int count;

  DayTrend(this.day, this.level, this.count);
}

class SiteAvgLevel {
  final String site;
  final double avgLevel;

  SiteAvgLevel(this.site, this.avgLevel);
}

class TimePeriodLevel {
  final String period;
  final double level;

  TimePeriodLevel(this.period, this.level);
}

enum Trend { up, down, stable }

class WaterChange {
  final double change;
  final Trend trend;
  final double percentage;

  const WaterChange({
    required this.change,
    required this.trend,
    required this.percentage,
  });

  const WaterChange.zero() : change = 0, trend = Trend.stable, percentage = 0;
}

int getReadingsByTimeRange(List<Reading> readings, String site, int hours) {
  final cutoff = DateTime.now().subtract(Duration(hours: hours));
  return readings.where((r) {
    final siteOk = site == 'all' || r.siteId == site;
    return siteOk && r.timestamp.isAfter(cutoff);
  }).length;
}

List<PieStat> getManualVsAutomated(List<Reading> readings) {
  final manual = readings.where((r) => r.isManual).length;
  final automated = readings.length - manual;
  return [
    PieStat('Manual', manual.toDouble(), const Color(0xff3b82f6)),
    PieStat('Automated', automated.toDouble(), const Color(0xff10b981)),
  ];
}

List<SiteCount> getSiteReadingsCount(List<Reading> readings) {
  final Map<String, int> counts = {};
  for (final r in readings) {
    counts[r.siteId] = (counts[r.siteId] ?? 0) + 1;
  }
  return counts.entries.map((e) => SiteCount(e.key, e.value)).toList()
    ..sort((a, b) => b.count.compareTo(a.count));
}

List<TimePeriodLevel> getTodayWaterLevels(List<Reading> readings, String site) {
  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);

  final todayReadings = readings.where((r) {
    if (r.siteId != site) return false;
    return r.timestamp.isAfter(todayStart);
  }).toList();

  List<Reading> filterBy(
    int startHour,
    int endHour, {
    bool wrapsMidnight = false,
  }) {
    return todayReadings.where((r) {
      final hour = r.timestamp.hour;
      if (wrapsMidnight) {
        return hour >= startHour || hour < endHour;
      } else {
        return hour >= startHour && hour < endHour;
      }
    }).toList();
  }

  double avg(List<Reading> list) {
    if (list.isEmpty) return 0;
    return list.map((e) => e.waterLevel).reduce((a, b) => a + b) / list.length;
  }

  final morning = filterBy(6, 12);
  final afternoon = filterBy(12, 18);
  final night = filterBy(18, 6, wrapsMidnight: true);

  return [
    TimePeriodLevel('Morning', avg(morning)),
    TimePeriodLevel('Afternoon', avg(afternoon)),
    TimePeriodLevel('Night', avg(night)),
  ];
}

List<DayTrend> getWeeklyTrend(List<Reading> readings, String site) {
  final List<DayTrend> list = [];
  final now = DateTime.now();

  for (int i = 6; i >= 0; i--) {
    final day = now.subtract(Duration(days: i));
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));

    final dayReadings = readings.where((r) {
      if (site != 'all' && r.siteId != site) return false;
      return r.timestamp.isAfter(start) && r.timestamp.isBefore(end);
    }).toList();

    double avg = 0;
    if (dayReadings.isNotEmpty) {
      avg =
          dayReadings.map((e) => e.waterLevel).reduce((a, b) => a + b) /
          dayReadings.length;
    }

    list.add(DayTrend(DateFormat.E().format(day), avg, dayReadings.length));
  }

  return list;
}

List<SiteAvgLevel> getHighestWaterLevelSite(List<Reading> readings) {
  final weekAgo = DateTime.now().subtract(const Duration(days: 7));
  final weekReadings = readings
      .where((r) => r.timestamp.isAfter(weekAgo))
      .toList();

  final Map<String, List<double>> siteValues = {};
  for (final r in weekReadings) {
    siteValues.putIfAbsent(r.siteId, () => []).add(r.waterLevel);
  }

  final list = siteValues.entries.map((e) {
    final avg = e.value.reduce((a, b) => a + b) / e.value.length;
    return SiteAvgLevel(e.key, avg);
  }).toList();

  list.sort((a, b) => b.avgLevel.compareTo(a.avgLevel));
  return list;
}

List<PieStat> getVerificationStats(List<Reading> readings) {
  final verified = readings.where((r) => r.isVerified).length;
  final unverified = readings.length - verified;
  return [
    PieStat('Verified', verified.toDouble(), const Color(0xff10b981)),
    PieStat('Pending', unverified.toDouble(), const Color(0xfff59e0b)),
  ];
}

WaterChange getWaterLevelChange(List<Reading> readings, String site) {
  final siteReadings = readings.where((r) => r.siteId == site).toList()
    ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

  if (siteReadings.length < 2) {
    return const WaterChange.zero();
  }

  final latest = siteReadings[0].waterLevel;
  final previous = siteReadings[1].waterLevel;
  final change = latest - previous;

  Trend trend;
  if (change > 0.1) {
    trend = Trend.up;
  } else if (change < -0.1) {
    trend = Trend.down;
  } else {
    trend = Trend.stable;
  }

  final percentage = previous == 0 ? 0 : (change / previous) * 100;

  return WaterChange(
    change: double.parse(change.toStringAsFixed(2)),
    trend: trend,
    percentage: double.parse(percentage.toStringAsFixed(1)),
  );
}

String _manualAutoInsight(List<PieStat> stats) {
  if (stats.length < 2) return 'No data available.';
  final manual = stats[0].value;
  final auto = stats[1].value;
  if (manual > auto) {
    return 'Insight: Manual readings dominate. Consider increasing automation for efficiency.';
  } else {
    return 'Insight: Automated readings are predominant. System is running efficiently.';
  }
}

String _siteReadingsInsight(List<SiteCount> list) {
  if (list.isEmpty) return 'No site data available.';
  final top = list.first;
  return 'Insight: Site ${top.site} has the most readings (${top.count}). Monitor less active sites to ensure coverage.';
}

String _weeklyTrendInsight(List<DayTrend> list) {
  if (list.length < 2) {
    return 'Not enough data to determine weekly trend.';
  }
  final first = list.first;
  final last = list.last;
  if (last.level > first.level) {
    return 'Insight: Weekly average shows an increasing trend. Monitor for possible flooding risks.';
  } else if (last.level < first.level) {
    return 'Insight: Weekly average shows a decreasing trend. Watch for potential drought conditions.';
  } else {
    return 'Insight: Weekly average appears stable.';
  }
}

String _highestSiteInsight(List<SiteAvgLevel> list) {
  if (list.isEmpty) {
    return 'No readings available for the last week.';
  }
  final top = list.first;
  return 'Alert: Site ${top.site} has the highest average water level (${top.avgLevel.toStringAsFixed(2)} m). Priority monitoring required.';
}

String _verificationInsight(List<PieStat> list) {
  if (list.length < 2) return 'No verification data.';
  final pending = list[1].value;
  if (pending > 10) {
    return 'Status: ${pending.toInt()} readings pending verification. Supervisor action needed.';
  } else if (pending > 0) {
    return 'Status: ${pending.toInt()} readings pending. System is mostly up to date.';
  } else {
    return 'Status: All readings verified. System up to date.';
  }
}

String _waterChangeText(WaterChange c) {
  if (c.trend == Trend.stable) {
    return 'Change: 0m (0%) - Water level is stable compared to the previous reading.';
  }
  final dir = c.trend == Trend.up ? 'rising' : 'falling';
  return 'Change: ${c.change}m (${c.percentage}%) - Water level is $dir compared to the previous reading.';
}
