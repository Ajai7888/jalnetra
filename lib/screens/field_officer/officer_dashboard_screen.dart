// lib/screens/field_officer/officer_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:jalnetra01/common/firebase_service.dart';
import 'package:jalnetra01/screens/auth/role_selection_screen.dart';
import 'package:jalnetra01/screens/field_officer/capture_flow_screen.dart';
import 'package:jalnetra01/screens/common/profile_screen.dart';
import 'package:jalnetra01/utils/constants.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../common/WeatherScreen.dart'; // Make sure WeatherScreen exists

class OfficerDashboardScreen extends StatefulWidget {
  const OfficerDashboardScreen({super.key});

  @override
  State<OfficerDashboardScreen> createState() => _OfficerDashboardScreenState();
}

class _OfficerDashboardScreenState extends State<OfficerDashboardScreen> {
  // ✔ Weather API Key
  final String _apiKey = '567ccd2e4f1ca68963303481ce41996b';

  String _currentLocationName = "Fetching Current Site...";
  bool _isLocationAvailable = false;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _fetchCurrentLocationName();
  }

  // -------- LOCATION FETCH ----------
  Future<void> _fetchCurrentLocationName() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      );
      _currentPosition = position;

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
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

  // -------- WEATHER FETCH BY GPS ----------
  Future<WeatherData?> _fetchWeatherDataByCoordinates(
    double lat,
    double lon,
  ) async {
    final currentUrl = Uri.parse(
      'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&units=metric&appid=$_apiKey',
    );

    try {
      final response = await http.get(currentUrl);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Weather icon logic
        String getWeatherIcon(int code) {
          if (code < 300) return '⛈️';
          if (code < 600) return '🌧️';
          if (code < 700) return '❄️';
          if (code < 800) return '🌫️';
          if (code == 800) return '☀️';
          if (code > 800) return '☁️';
          return '❓';
        }

        final apiCityName = data['name'] ?? 'Current Location';

        int rainChanceMock =
            (data['weather'][0]['main'] == 'Rain' ||
                data['weather'][0]['main'] == 'Drizzle')
            ? 70
            : 0;

        return WeatherData(
          weatherIcon: getWeatherIcon(data['weather'][0]['id']),
          temperature: data['main']['temp'],
          humidity: data['main']['humidity'],
          windSpeed: data['wind']['speed'] * 3.6, // m/s → km/h
          rainChance: rainChanceMock,
          description: data['weather'][0]['description'],
          location: apiCityName,
        );
      } else {
        debugPrint("Weather API Error: ${response.statusCode}");
        _showSnackBar("Weather API Error", Colors.red);
        return null;
      }
    } catch (e) {
      debugPrint("Weather Exception: $e");
      return null;
    }
  }

  // -------- WEATHER BUTTON HANDLER ----------
  void _handleWeatherCheck() async {
    if (_currentPosition == null) {
      _showSnackBar("GPS unavailable. Enable location services.", Colors.red);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fetching live weather data...')),
    );

    final weather = await _fetchWeatherDataByCoordinates(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (weather != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                WeatherScreen(weather: weather, location: weather.location),
          ),
        );
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  // ============ UI =============
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Field Personnel Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_queue),
            onPressed: _currentPosition != null ? _handleWeatherCheck : null,
            tooltip: 'Check Weather',
          ),
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

          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
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

          // Floating Action Button
          Positioned(
            bottom: 30,
            left: MediaQuery.of(context).size.width / 2 - 35,
            child: SizedBox(
              height: 70,
              width: 70,
              child: FloatingActionButton(
                onPressed: _isLocationAvailable
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CaptureFlowScreen(),
                          ),
                        );
                      }
                    : null,
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
