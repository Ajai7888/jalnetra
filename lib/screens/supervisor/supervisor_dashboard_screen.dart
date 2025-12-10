// lib/screens/supervisor/supervisor_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:steganograph/steganograph.dart';
import 'package:photo_view/photo_view.dart';

import 'package:jalnetra01/common/firebase_service.dart';
import 'package:jalnetra01/models/reading_model.dart';
import 'package:jalnetra01/screens/auth/role_selection_screen.dart';
import 'package:jalnetra01/screens/common/profile_screen.dart';
import 'package:jalnetra01/screens/supervisor/supervisor_map_view.dart';
import 'package:jalnetra01/screens/supervisor/supervisor_alerts_view.dart';
import 'package:jalnetra01/screens/common/water_level_trend_charts.dart';

import '../../jalnetra_storage_image.dart';

enum DateFilter { all, today, week, month }

const List<String> kWaterSites = [
  'PUZHAL',
  'VEERANAM',
  'CHEMBARAMBAKAM',
  'CHOLAVARAM',
  'POONDI',
];

class SupervisorDashboardScreen extends StatefulWidget {
  const SupervisorDashboardScreen({super.key});

  @override
  State<SupervisorDashboardScreen> createState() =>
      _SupervisorDashboardScreenState();
}

class _SupervisorDashboardScreenState extends State<SupervisorDashboardScreen> {
  DateFilter _currentFilter = DateFilter.all;

  // 0 = COMMUNITY INPUTS, 1 = HISTORY, 2 = MAP, 3 = ALERTS, 4 = TRENDS
  int _selectedIndex = 0;

  String _currentSiteFilter = kWaterSites.first;

  final List<String> _pageTitles = [
    'Community Inputs',
    'Verification History',
    'Map View',
    'Alerts & Incidents',
    'Water Level Trends',
  ];

  final List<IconData> _pageIcons = [
    Icons.people,
    Icons.history,
    Icons.map,
    Icons.warning_amber,
    Icons.show_chart,
  ];

  /// 🔧 Helper to fix old/bad Firebase Storage URLs (used for network calls)
  String _fixImageUrl(String url) {
    var fixed = url.trim();

    fixed = fixed.replaceFirst(
      'jalnetra-44a79.firebasestorage.app',
      'jalnetra-44a79.appspot.com',
    );

    fixed = fixed.replaceFirst('firebasestorage.app', 'appspot.com');

    return fixed;
  }

  // Apply date filter
  List<WaterReading> _applyFilter(List<WaterReading> readings) {
    final now = DateTime.now();

    return readings.where((r) {
      final diff = now.difference(r.timestamp).inDays;
      switch (_currentFilter) {
        case DateFilter.today:
          return diff == 0;
        case DateFilter.week:
          return diff < 7;
        case DateFilter.month:
          return diff < 30;
        case DateFilter.all:
        default:
          return true;
      }
    }).toList();
  }

  Widget _getBodyWidget() {
    switch (_selectedIndex) {
      case 0:
        return _buildCommunityInputsQueue();
      case 1:
        return _buildHistoryView();
      case 2:
        return const SupervisorMapView();
      case 3:
        return const SupervisorAlertsView();
      case 4:
        return _buildTrendView();
      default:
        return _buildCommunityInputsQueue();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('JALNETRA - Supervisor (${_pageTitles[_selectedIndex]})'),
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
      drawer: _buildDrawer(context),
      body: _getBodyWidget(),
    );
  }

  // ───────── DRAWER ─────────

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Column(
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(color: Theme.of(context).primaryColor),
              child: const SizedBox(
                width: double.infinity,
                child: Text(
                  'Supervisor Menu',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            for (int i = 0; i < _pageTitles.length; i++)
              ListTile(
                leading: Icon(
                  _pageIcons[i],
                  color: _selectedIndex == i
                      ? Theme.of(context).primaryColor
                      : Colors.white70,
                ),
                title: Text(
                  _pageTitles[i],
                  style: TextStyle(
                    color: _selectedIndex == i
                        ? Theme.of(context).primaryColor
                        : Colors.white,
                  ),
                ),
                selected: _selectedIndex == i,
                onTap: () {
                  setState(() => _selectedIndex = i);
                  Navigator.pop(context);
                },
              ),
            const Spacer(),
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

  // ───────── COMMUNITY INPUTS (PENDING QUEUE) ─────────

  Widget _buildCommunityInputsQueue() {
    return StreamBuilder<List<WaterReading>>(
      stream: FirebaseService().getCommunityInputs(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final allReadings = snapshot.data ?? [];
        final filteredReadings = _applyFilter(allReadings);

        return _buildListBody(
          context,
          filteredReadings,
          allReadings,
          isPendingQueue: true,
        );
      },
    );
  }

  // ───────── HISTORY VIEW (VERIFIED) ─────────

  Widget _buildHistoryView() {
    return StreamBuilder<List<WaterReading>>(
      stream: FirebaseService().getAllVerifiedReadings(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final allReadings = snapshot.data ?? [];
        final filteredReadings = _applyFilter(allReadings);

        return _buildListBody(
          context,
          filteredReadings,
          allReadings,
          isPendingQueue: false,
        );
      },
    );
  }

  // ───────── TRENDS VIEW ─────────

  Widget _buildTrendView() {
    return StreamBuilder<List<WaterReading>>(
      stream: FirebaseService().getAllVerifiedReadings(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final readings = snapshot.data ?? [];

        if (readings.isEmpty) {
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
              _buildSiteDropdown(),
              const SizedBox(height: 16),
              WaterLevelTrendCharts(
                allReadings: readings,
                title:
                    "Supervisor Trend Analysis (${readings.length} Total Readings)",
                selectedSite: _currentSiteFilter,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSiteDropdown() {
    return DropdownButton<String>(
      value: _currentSiteFilter,
      dropdownColor: Colors.grey.shade900,
      onChanged: (String? newValue) {
        if (newValue != null) {
          setState(() => _currentSiteFilter = newValue);
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

  // ───────── COMMON LIST BODY ─────────

  Widget _buildListBody(
    BuildContext context,
    List<WaterReading> filteredReadings,
    List<WaterReading> allReadings, {
    required bool isPendingQueue,
  }) {
    if (filteredReadings.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 50.0),
          child: Text(
            isPendingQueue
                ? 'No community inputs pending verification for this period.'
                : 'No verified history for this period.',
            style: const TextStyle(fontSize: 18, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_selectedIndex <= 1) _buildFilterDropdown(),
          const SizedBox(height: 10),
          ...filteredReadings
              .map(
                (reading) => _buildVerificationCard(
                  context,
                  reading,
                  allReadings,
                  isPendingQueue: isPendingQueue,
                ),
              )
              .toList(),
          const SizedBox(height: 20),
          _buildRecentActivity(),
        ],
      ),
    );
  }

  // ───────── DATE FILTER DROPDOWN ─────────

  Widget _buildFilterDropdown() {
    return DropdownButton<DateFilter>(
      value: _currentFilter,
      dropdownColor: Colors.grey.shade900,
      onChanged: (DateFilter? newValue) {
        if (newValue != null) {
          setState(() => _currentFilter = newValue);
        }
      },
      items: DateFilter.values.map((DateFilter filter) {
        return DropdownMenuItem<DateFilter>(
          value: filter,
          child: Text(filter.name.toUpperCase()),
        );
      }).toList(),
    );
  }

  // ───────── FORENSIC HELPERS ─────────

  WaterReading? _getPreviousReading(
    WaterReading current,
    List<WaterReading> allReadings,
  ) {
    final previousReadings = allReadings
        .where(
          (r) =>
              r.siteId == current.siteId &&
              r.timestamp.isBefore(current.timestamp),
        )
        .toList();

    if (previousReadings.isEmpty) return null;

    return previousReadings.reduce(
      (a, b) => a.timestamp.isAfter(b.timestamp) ? a : b,
    );
  }

  Future<Map<String, String>> _decodeStegMetadataFromUrl(
    String imageUrl,
  ) async {
    try {
      // 🔧 ensure URL is valid before calling the server
      final fixedUrl = _fixImageUrl(imageUrl);

      final resp = await http.get(Uri.parse(fixedUrl));
      if (resp.statusCode != 200) {
        return {"Error": 'Failed to download image: ${resp.statusCode}'};
      }

      final hiddenMessage = await Steganograph.uncloakBytes(resp.bodyBytes);
      if (hiddenMessage == null || hiddenMessage.isEmpty) {
        return {"Error": 'No hidden metadata found in image.'};
      }

      final Map<String, String> data = {};
      for (final pair in hiddenMessage.split('|')) {
        if (pair.trim().isEmpty) continue;
        final idx = pair.indexOf(':');
        if (idx == -1) continue;
        final key = pair.substring(0, idx);
        final value = pair.substring(idx + 1);
        data[key] = value;
      }

      return data;
    } catch (e) {
      debugPrint("Steganography Decode Error: $e");
      return {"Error": "Error during decryption: ${e.toString()}"};
    }
  }

  void _showFullImage(BuildContext context, String imageUrl) {
    final fixedUrl = _fixImageUrl(imageUrl);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text("Gauge Image Forensics")),
          body: PhotoView(
            imageProvider: NetworkImage(fixedUrl),
            heroAttributes: PhotoViewHeroAttributes(tag: fixedUrl),
          ),
        ),
      ),
    );
  }

  Future<void> _showStegDetailsDialog(
    BuildContext context,
    WaterReading reading,
  ) async {
    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final meta = await _decodeStegMetadataFromUrl(reading.imageUrl);

      final stegLevelRaw = meta['Level'] ?? 'N/A';
      double? stegLevel;
      if (stegLevelRaw.endsWith('m')) {
        final numPart = stegLevelRaw.substring(0, stegLevelRaw.length - 1);
        stegLevel = double.tryParse(numPart);
      }

      if (!context.mounted) return;
      Navigator.pop(context); // close loading

      showDialog(
        context: context,
        builder: (_) {
          return AlertDialog(
            title: const Text('Embedded Image Metadata'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Status: ${meta['Error'] ?? 'Decryption Successful'}',
                    style: TextStyle(
                      color: meta.containsKey('Error')
                          ? Colors.red
                          : Colors.green,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('SiteID (Steg): ${meta['SiteID'] ?? 'N/A'}'),
                  Text('Officer Email: ${meta['OfficerEmail'] ?? 'N/A'}'),
                  const Divider(),
                  Text(
                    'Water Level (DB): ${reading.waterLevel.toStringAsFixed(2)} m',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Water Level (Steg): ${meta['Level'] ?? 'N/A'}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (stegLevel != null)
                    Text(
                      'Difference: ${(reading.waterLevel - stegLevel).toStringAsFixed(3)} m',
                    ),
                  const SizedBox(height: 8),
                  Text(
                    'Live GPS (Steg): ${meta['GeoLiveLat'] ?? 'N/A'}, ${meta['GeoLiveLon'] ?? 'N/A'}',
                  ),
                  Text('Timestamp (Steg): ${meta['Timestamp'] ?? 'N/A'}'),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context); // close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to initialize dialog: $e')),
      );
    }
  }

  // ───────── SINGLE READING CARD ─────────

  Widget _buildVerificationCard(
    BuildContext context,
    WaterReading reading,
    List<WaterReading> allReadings, {
    required bool isPendingQueue,
  }) {
    final prevReading = _getPreviousReading(reading, allReadings);
    final dateFormat = DateFormat('yyyy-MM-dd hh:mm a');
    final FirebaseService service = FirebaseService();

    final bool isApproved = reading.isVerified;
    final Color statusColor;
    final String statusText;

    if (isPendingQueue) {
      statusColor = Colors.orange;
      statusText = "PENDING";
    } else {
      statusColor = isApproved ? Colors.green : Colors.red;
      statusText = isApproved ? "APPROVED" : "REJECTED";
    }

    final entryTypeText = reading.isManual ? 'Manual Entry' : 'Automatic (SLV)';
    final entryTypeColor = reading.isManual
        ? Colors.amber
        : const Color(0xFF4CAF50);

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // STATUS BADGE
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
            decoration: BoxDecoration(color: statusColor.withOpacity(0.9)),
            child: Text(
              statusText,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // IMAGE PREVIEW
          GestureDetector(
            onTap: () {
              if (reading.imageUrl.isNotEmpty) {
                _showFullImage(context, reading.imageUrl);
              }
            },
            child: Hero(
              tag: _fixImageUrl(reading.imageUrl),
              child: SizedBox(
                height: 180,
                width: double.infinity,
                child: reading.imageUrl.isEmpty
                    ? const Center(child: Text('No Image'))
                    : JalnetraStorageImage(
                        imageUrl: reading.imageUrl,
                        width: double.infinity,
                        height: 180,
                        fit: BoxFit.cover,
                      ),
              ),
            ),
          ),

          // DETAILS + ACTIONS
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Site ID: ${reading.siteId}",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Measured Level (DB): ${reading.waterLevel.toStringAsFixed(2)} m",
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF4CAF50),
                  ),
                ),
                if (prevReading != null)
                  Text(
                    "Previous Level: ${prevReading.waterLevel.toStringAsFixed(2)} m (${DateFormat('MMM d').format(prevReading.timestamp)})",
                    style: const TextStyle(color: Colors.grey),
                  ),
                const SizedBox(height: 6),
                Text(
                  "Entry Type: $entryTypeText",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: entryTypeColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Officer ID: ${reading.officerId}",
                  style: const TextStyle(color: Colors.grey),
                ),
                Text(
                  "Timestamp: ${dateFormat.format(reading.timestamp)}",
                  style: const TextStyle(color: Colors.grey),
                ),
                Text(
                  "Location: Lat:${reading.location.latitude.toStringAsFixed(2)} "
                  "Lon:${reading.location.longitude.toStringAsFixed(2)}",
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 12),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => _showStegDetailsDialog(context, reading),
                    icon: const Icon(Icons.verified),
                    label: const Text("Verify Image Metadata"),
                  ),
                ),

                const SizedBox(height: 8),

                if (isPendingQueue)
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => service.updateVerificationStatus(
                            reading.id,
                            true,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                          ),
                          child: const Text("APPROVE"),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => service.updateVerificationStatus(
                            reading.id,
                            false,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          child: const Text("REJECT & NOTIFY"),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ───────── RECENT ACTIVITY (MOCK) ─────────

  Widget _buildRecentActivity() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "RECENT ACTIVITY (Mock)",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildActivityItem(
              "Supervisor approved reading KL505 at Hooghly River.",
              Icons.check_circle,
              Colors.green,
            ),
            _buildActivityItem(
              "Field Officer MHP012 submitted reading at Godavari River.",
              Icons.upload_file,
              Colors.blue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(String activity, IconData icon, Color color) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.2),
        child: Icon(icon, color: color),
      ),
      title: Text(activity, style: const TextStyle(fontSize: 14)),
      dense: true,
    );
  }
}
