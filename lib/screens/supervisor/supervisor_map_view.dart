// lib/screens/supervisor/supervisor_map_view.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart'; // Core Map Widget
import 'package:latlong2/latlong.dart'; // Coordinates and utilities

// Mock data structure remains the same
class MockSiteData {
  final String id;
  final LatLng coords;
  final double level;
  final bool isOffline;

  MockSiteData({
    required this.id,
    required this.coords,
    required this.level,
    required this.isOffline,
  });
}

class SupervisorMapView extends StatelessWidget {
  const SupervisorMapView({super.key});

  // --- MOCK SITE DATA FOR MAP PLOTTING (Updated with new locations) ---
  List<MockSiteData> _fetchMockSites() {
    return [
      // 1. PUZHAL (High Alert)
      MockSiteData(
        id: 'PUZHAL',
        coords: LatLng(13.1667, 80.1715),
        level: 4.8, // High Alert
        isOffline: false,
      ),
      // 2. VEERANAM (Normal - Note: Far South, map center adjusted)
      MockSiteData(
        id: 'VEERANAM',
        coords: LatLng(11.3216, 79.5435),
        level: 2.9, // Normal
        isOffline: false,
      ),
      // 3. CHEMBARAMBAKAM (Warning)
      MockSiteData(
        id: 'CHEMBA',
        coords: LatLng(13.0114, 80.0591),
        level: 3.7, // Warning
        isOffline: false,
      ),
      // 4. CHOLAVARAM (Normal)
      MockSiteData(
        id: 'CHOLAVARAM',
        coords: LatLng(13.2276, 80.1502),
        level: 1.9, // Normal
        isOffline: false,
      ),
      // 5. POONDI (Offline)
      MockSiteData(
        id: 'POONDI',
        coords: LatLng(13.1858, 79.8577),
        level: 0.0,
        isOffline: true, // Offline
      ),
    ];
  }

  // --- LOGIC TO DETERMINE MARKER COLOR/ICON (Remains the same) ---
  Color _getSiteColor(MockSiteData site) {
    if (site.isOffline) return Colors.grey;
    if (site.level >= 4.5) return Colors.red; // Flood/High Alert
    if (site.level >= 3.5) return Colors.orange; // Warning/Pre-Alert
    return Colors.green; // Normal
  }

  @override
  Widget build(BuildContext context) {
    final sites = _fetchMockSites();

    // Calculate a good center point between the northern sites and Veeranam (south)
    // We'll center slightly north of the midpoint and zoom out a bit.
    const initialCenterLat = 12.5;
    const initialCenterLon = 80.0;
    // Zoom 8 is required to see all sites from Puzhal down to Veeranam.
    const initialZoomLevel = 8.0;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Geo-Spatial Site Overview',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Text(
              'Visualizing active, alert, and offline monitoring sites.',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 15),

            // --- MAP INTEGRATION AREA ---
            Container(
              height: 400,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blueGrey.shade700),
              ),
              child: FlutterMap(
                options: const MapOptions(
                  // UPDATED CENTER AND ZOOM to show all sites
                  initialCenter: LatLng(initialCenterLat, initialCenterLon),
                  initialZoom: initialZoomLevel,
                ),
                children: [
                  // 1. Tile Layer (OpenStreetMap background)
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.jalnetra01',
                  ),

                  // 2. Marker Layer (Plotting the sites)
                  MarkerLayer(
                    markers: sites.map((site) {
                      final color = _getSiteColor(site);
                      return Marker(
                        width: 100.0,
                        height: 50.0,
                        point: site.coords,
                        child: Column(
                          children: [
                            Text(
                              site.id,
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                            Icon(Icons.location_on, size: 25, color: color),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            // --- END MAP INTEGRATION AREA ---
            const SizedBox(height: 20),

            // Map Legend
            const Text(
              "Map Legend:",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            _buildLegendItem(Colors.red, "High Alert (> 4.5m)"),
            _buildLegendItem(Colors.orange, "Warning (> 3.5m)"),
            _buildLegendItem(Colors.green, "Normal"),
            _buildLegendItem(Colors.grey, "Offline"),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.circle, size: 12, color: color),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}
