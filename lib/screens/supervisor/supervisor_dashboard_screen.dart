// lib/screens/supervisor/supervisor_dashboard_screen.dart

import 'dart:typed_data';
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

enum DateFilter { all, today, week, month }

// ----------------------------------------------------------------------
// MAIN STATEFUL WIDGET
// ----------------------------------------------------------------------

class SupervisorDashboardScreen extends StatefulWidget {
  const SupervisorDashboardScreen({super.key});

  @override
  State<SupervisorDashboardScreen> createState() =>
      _SupervisorDashboardScreenState();
}

class _SupervisorDashboardScreenState extends State<SupervisorDashboardScreen> {
  // State to manage date filtering (used within the stream builders)
  DateFilter _currentFilter = DateFilter.all;

  // New state to manage the currently displayed section (Drawer navigation)
  int _selectedIndex = 0; // 0=PENDING, 1=HISTORY, 2=MAP, 3=ALERTS

  final List<String> _pageTitles = [
    'Verification Queue',
    'Verification History',
    'Map View',
    'Alerts & Incidents',
  ];

  final List<IconData> _pageIcons = [
    Icons.pending_actions,
    Icons.history,
    Icons.map,
    Icons.warning_amber,
  ];

  // Function to apply filtering based on the selected criteria
  List<WaterReading> _applyFilter(List<WaterReading> readings) {
    final now = DateTime.now();

    return readings.where((r) {
      final diff = now.difference(r.timestamp).inDays;
      if (_currentFilter == DateFilter.today) {
        return diff == 0;
      } else if (_currentFilter == DateFilter.week) {
        return diff < 7;
      } else if (_currentFilter == DateFilter.month) {
        return diff < 30;
      }
      return true; // DateFilter.all
    }).toList();
  }

  // --- Widget for the current body content ---
  Widget _getBodyWidget() {
    switch (_selectedIndex) {
      case 0:
        return _buildVerificationQueue();
      case 1:
        return _buildHistoryView();
      case 2:
        return const SupervisorMapView();
      case 3:
        return const SupervisorAlertsView();
      default:
        return _buildVerificationQueue();
    }
  }

  // ----------------------------------------------------------------------
  // BUILD METHOD (REFRACTORED TO USE DRAWER)
  // ----------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 1. Remove DefaultTabController, use standard Scaffold
      appBar: AppBar(
        title: Text('JALNETRA - Supervisor (${_pageTitles[_selectedIndex]})'),
        // No 'bottom' property here
        actions: [
          // Profile Button
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
          // Logout Button
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

      // 2. Add Drawer (The new menu bar)
      drawer: _buildDrawer(context),

      // 3. Body shows the selected widget
      body: _getBodyWidget(),
    );
  }

  // ───────────────── DRAWER IMPLEMENTATION ─────────────────

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Container(
        color: Theme.of(context).scaffoldBackgroundColor, // Dark background
        child: Column(
          children: <Widget>[
            // Drawer Header
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
              ),
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

            // Navigation List Items
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
                  setState(() {
                    _selectedIndex = i;
                  });
                  Navigator.pop(context); // Close the drawer
                },
              ),

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

  // ───────────────── STREAM BUILDERS (USED IN BODY) ─────────────────

  Widget _buildVerificationQueue() {
    return StreamBuilder<List<WaterReading>>(
      stream: FirebaseService().getPendingVerifications(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final allReadings = snapshot.data ?? [];
        final totalSubmissions = 500; // Mocked
        final filteredReadings = _applyFilter(allReadings);

        return _buildListBody(
          context,
          filteredReadings,
          allReadings,
          pendingTotal: allReadings.length,
          totalSubmissions: totalSubmissions,
          isPendingQueue: true,
        );
      },
    );
  }

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
        final totalSubmissions = 500; // Mocked
        final filteredReadings = _applyFilter(allReadings);

        return _buildListBody(
          context,
          filteredReadings,
          allReadings,
          totalSubmissions: totalSubmissions,
          isPendingQueue: false,
        );
      },
    );
  }

  // ───────────────── COMMON LIST BODY ─────────────────

  Widget _buildListBody(
    BuildContext context,
    List<WaterReading> filteredReadings,
    List<WaterReading> allReadings, {
    int pendingTotal = 0,
    required int totalSubmissions,
    required bool isPendingQueue,
  }) {
    if (filteredReadings.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.only(top: 50.0),
          child: Text(
            'No readings for this period.',
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
          // System Overview is only displayed in the PENDING tab (index 0)
          if (_selectedIndex == 0)
            _buildSystemOverview(
              pendingTotal,
              filteredReadings.length,
              totalSubmissions,
            ),

          const SizedBox(height: 20),
          // Only show filter for the PENDING and HISTORY tabs
          if (_selectedIndex <= 1) _buildFilterDropdown(),
          const SizedBox(height: 10),

          // Verification List
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

  // ───────────────── FILTER DROPDOWN ─────────────────

  Widget _buildFilterDropdown() {
    return DropdownButton<DateFilter>(
      value: _currentFilter,
      dropdownColor: Colors.grey.shade900,
      onChanged: (DateFilter? newValue) {
        if (newValue != null) {
          setState(() {
            _currentFilter = newValue;
          });
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

  // ───────────────── OVERVIEW CARD ─────────────────

  Widget _buildSystemOverview(
    int pendingTotal,
    int pendingFiltered,
    int totalSubmissions,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "SYSTEM OVERVIEW",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildStatRow(
              "TOTAL SUBMISSIONS (Lifetime)",
              totalSubmissions.toString(),
            ),
            _buildStatRow("TOTAL PENDING (All Time)", pendingTotal.toString()),
            _buildStatRow("PENDING (Filtered)", pendingFiltered.toString()),
            _buildStatRow("ACTIVE SITES", "187 (Mock)"),
            _buildStatRow("OFFLINE SITES", "5 (Mock)"),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ───────────────── FORENSIC HELPER FUNCTIONS ─────────────────

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

    if (previousReadings.isEmpty) {
      return null;
    }

    return previousReadings.reduce(
      (a, b) => a.timestamp.isAfter(b.timestamp) ? a : b,
    );
  }

  /// Downloads the image from [imageUrl], extracts the hidden message,
  /// and returns it as a key-value map.
  Future<Map<String, String>> _decodeStegMetadataFromUrl(
    String imageUrl,
  ) async {
    try {
      final resp = await http.get(Uri.parse(imageUrl));
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

  /// Displays the full-screen zoomable image when the thumbnail is tapped.
  void _showFullImage(BuildContext context, String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text("Gauge Image Forensics")),
          body: PhotoView(
            imageProvider: NetworkImage(imageUrl),
            heroAttributes: PhotoViewHeroAttributes(tag: imageUrl),
          ),
        ),
      ),
    );
  }

  /// Shows a dialog with decoded steganography details.
  Future<void> _showStegDetailsDialog(
    BuildContext context,
    WaterReading reading,
  ) async {
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

      if (context.mounted) {
        Navigator.pop(context); // close loading dialog

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
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to initialize dialog: $e')),
        );
      }
    }
  }

  // ───────────────── SINGLE READING CARD ─────────────────

  Widget _buildVerificationCard(
    BuildContext context,
    WaterReading reading,
    List<WaterReading> allReadings, {
    required bool isPendingQueue,
  }) {
    // Get previous reading details for comparison
    final prevReading = _getPreviousReading(reading, allReadings);

    final dateFormat = DateFormat('yyyy-MM-dd hh:mm a');
    final FirebaseService service = FirebaseService();

    // Determine status badge color and text
    final bool isApproved = reading.isVerified;
    final statusColor = isPendingQueue
        ? Colors.transparent
        : (isApproved ? Colors.green : Colors.red);
    final statusText = isPendingQueue
        ? "PENDING"
        : (isApproved ? "APPROVED" : "REJECTED");

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
              style: TextStyle(
                color: isPendingQueue ? Colors.orange : Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // IMAGE PREVIEW (Tap to open full screen)
          GestureDetector(
            onTap: () => _showFullImage(context, reading.imageUrl),
            child: Hero(
              tag: reading.imageUrl, // For smooth transition
              child: SizedBox(
                height: 180,
                width: double.infinity,
                child: Image.network(
                  reading.imageUrl,
                  fit: BoxFit.cover,
                  // NOTE: Original image builders are omitted here, but should be added for robustness
                ),
              ),
            ),
          ),

          // TEXT + ACTIONS
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Site ID and Level
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

                // Historical Comparison
                if (prevReading != null)
                  Text(
                    "Previous Level: ${prevReading.waterLevel.toStringAsFixed(2)} m (${DateFormat('MMM d').format(prevReading.timestamp)})",
                    style: const TextStyle(color: Colors.grey),
                  ),
                const SizedBox(height: 8),

                // Metadata
                Text(
                  "Timestamp: ${dateFormat.format(reading.timestamp)}",
                  style: const TextStyle(color: Colors.grey),
                ),
                Text(
                  "Location: Lat:${reading.location.latitude.toStringAsFixed(2)} Lon:${reading.location.longitude.toStringAsFixed(2)}",
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 12),

                // BUTTON TO DECODE STEGANOGRAPHY METADATA
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => _showStegDetailsDialog(context, reading),
                    icon: const Icon(Icons.verified),
                    label: const Text("Verify Image Metadata"),
                  ),
                ),

                const SizedBox(height: 8),

                // ACTION BUTTONS (Only visible for PENDING queue)
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

  // ───────────────── RECENT ACTIVITY (MOCK) ─────────────────

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
