// lib/screens/supervisor/supervisor_map_view.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class SupervisorMapView extends StatelessWidget {
  const SupervisorMapView({super.key});

  // Single site: Chembarambakkam
  LatLng get _chembarambakkamCoords => const LatLng(13.0114, 80.0591);

  @override
  Widget build(BuildContext context) {
    const initialCenterLat = 13.0114;
    const initialCenterLon = 80.0591;
    const initialZoomLevel = 12.0;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          const Text(
            'Chembarambakkam Site Location',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          const Text(
            'Map view with marker on Chembarambakkam.',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 15),

          SizedBox(
            height: 350,
            width: double.infinity,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blueGrey.shade700),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: FlutterMap(
                  options: const MapOptions(
                    initialCenter: LatLng(initialCenterLat, initialCenterLon),
                    initialZoom: initialZoomLevel,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.jalnetra01',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          // Marker size is 120.0 x 60.0
                          width: 120.0,
                          height: 60.0,
                          point: _chembarambakkamCoords,
                          child: const Column(
                            mainAxisSize: MainAxisSize.min,
                            // Ensure the content fits within the marker's width
                            children: [
                              // Added TextOverflow.ellipsis and softened font size slightly
                              // to prevent the text from causing overflow.
                              SizedBox(
                                width: 120,
                                child: Text(
                                  'Chembarambakkam',
                                  style: TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11, // Reduced font size slightly
                                  ),
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Icon(
                                Icons.location_on,
                                size: 32,
                                color: Colors.blue,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
