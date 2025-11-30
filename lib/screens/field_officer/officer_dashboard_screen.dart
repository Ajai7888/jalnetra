// lib/screens/field_officer/officer_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:jalnetra01/common/firebase_service.dart';
import 'package:jalnetra01/screens/auth/role_selection_screen.dart';
import 'package:jalnetra01/screens/field_officer/capture_flow_screen.dart';
import 'package:jalnetra01/screens/common/profile_screen.dart'; // Import for Profile Access
import 'package:jalnetra01/utils/constants.dart';

class OfficerDashboardScreen extends StatefulWidget {
  const OfficerDashboardScreen({super.key});

  @override
  State<OfficerDashboardScreen> createState() => _OfficerDashboardScreenState();
}

class _OfficerDashboardScreenState extends State<OfficerDashboardScreen> {
  String _currentLocationName = "Fetching Current Site...";
  bool _isLocationAvailable = false;
  Position?
  _currentPosition; // Stores current GPS position for Reverse Geocoding

  @override
  void initState() {
    super.initState();
    _fetchCurrentLocationName();
  }

  /// Fetches the user's current GPS position and translates it into a readable address.
  Future<void> _fetchCurrentLocationName() async {
    try {
      // 1. Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      );
      _currentPosition = position; // Store position for use in the Capture Flow

      // 2. Reverse Geocoding to get address
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        // Use a combination of name/street/sublocality for a readable address
        String address = "${p.name}, ${p.subLocality ?? p.locality}";

        if (mounted) {
          setState(() {
            _currentLocationName = address;
            _isLocationAvailable = true;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching location: $e");
      if (mounted) {
        setState(() {
          _currentLocationName = "Location Unavailable. Check GPS/Permissions.";
          _isLocationAvailable = false;
          _currentPosition = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Field Personnel Dashboard'),
        actions: [
          // 1. Profile Button
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
            tooltip: 'View Profile',
          ),
          // 2. Logout Button
          IconButton(
            icon: const Icon(Icons.logout),
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
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Clear map-like container replacing the asset
          Center(
            child: Container(
              color: Colors.blueGrey.shade900,
              width: double.infinity,
              height: double.infinity,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map, size: 80, color: Colors.white54),
                    SizedBox(height: 10),
                    Text(
                      'Live Geo-Tracking Placeholder',
                      style: TextStyle(color: Colors.white54, fontSize: 18),
                    ),
                    Text(
                      'Showing current location and geofence for readings.',
                      style: TextStyle(color: Colors.white54, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Current Site Card (Displays Live Location Name)
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Card(
              color: Theme.of(context).cardColor,
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    // Show a spinning icon while fetching location name
                    _isLocationAvailable
                        ? const Icon(
                            Icons.my_location,
                            color: Color(0xFF4CAF50),
                          )
                        : const CircularProgressIndicator(strokeWidth: 2),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _currentLocationName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Floating Action Button (Triggers Capture Flow)
          Positioned(
            bottom: 30,
            left: MediaQuery.of(context).size.width / 2 - 35,
            child: SizedBox(
              height: 70,
              width: 70,
              child: FloatingActionButton(
                onPressed:
                    _isLocationAvailable // Only allow capture if location is available
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            // Launch CaptureFlowScreen, which handles its own location check on step 1
                            builder: (_) => const CaptureFlowScreen(),
                          ),
                        );
                      }
                    : null, // Disable button if location is unavailable
                backgroundColor: _isLocationAvailable
                    ? Theme.of(context).primaryColor
                    : Colors.grey,
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 35,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
