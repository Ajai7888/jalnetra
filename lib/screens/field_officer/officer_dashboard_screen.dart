// lib/screens/field_officer/officer_dashboard_screen.dart

import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart'; // Needed for SOS sender email
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:jalnetra01/common/firebase_service.dart';
import 'package:jalnetra01/screens/auth/role_selection_screen.dart';
import 'package:jalnetra01/screens/common/profile_screen.dart';
import 'package:jalnetra01/screens/field_officer/capture_flow_screen.dart';

import '../../l10n/app_localizations.dart';
import '../common/WeatherScreen.dart';
import '../../../main.dart';

class OfficerDashboardScreen extends StatefulWidget {
  const OfficerDashboardScreen({super.key});

  @override
  State<OfficerDashboardScreen> createState() => _OfficerDashboardScreenState();
}

class _OfficerDashboardScreenState extends State<OfficerDashboardScreen> {
  final String _apiKey = '567ccd2e4f1ca68963303481ce41996b';

  String _currentLocationName = "Fetching Current Site...";
  bool _isLocationAvailable = false;
  Position? _currentPosition;

  // SOS Controllers and Services
  final TextEditingController _sosMessageController = TextEditingController();
  final FirebaseService _firebaseService = FirebaseService();
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _fetchCurrentLocationName();
  }

  @override
  void dispose() {
    _sosMessageController.dispose();
    super.dispose();
  }

  Future<bool> _isSecureEnvironmentForLocation() async {
    // Hook for root/jailbreak/emulator checks if needed.
    return true;
  }

  Future<void> _fetchCurrentLocationName() async {
    try {
      final safe = await _isSecureEnvironmentForLocation();
      if (!safe) return;

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception("Location services disabled");

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception("Location permission denied");
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      );
      _currentPosition = position;

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty && mounted) {
        final p = placemarks.first;
        final address = "${p.name}, ${p.subLocality ?? p.locality}";
        setState(() {
          _currentLocationName = address;
          _isLocationAvailable = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _currentLocationName = AppLocalizations.of(
            context,
          )!.locationUnavailable;
          _isLocationAvailable = false;
          _currentPosition = null;
        });
      }
    }
  }

  Future<WeatherData?> _fetchWeatherDataByCoordinates(
    double lat,
    double lon,
  ) async {
    final url = Uri.parse(
      'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&units=metric&appid=$_apiKey',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        String icon(int code) {
          if (code < 300) return '⛈️';
          if (code < 600) return '🌧️';
          if (code < 700) return '❄️';
          if (code < 800) return '🌫️';
          if (code == 800) return '☀️';
          if (code > 800) return '☁️';
          return '❓';
        }

        final rainChanceMock =
            (data['weather'][0]['main'] == 'Rain' ||
                data['weather'][0]['main'] == 'Drizzle')
            ? 70
            : 0;

        // NOTE: Dynamic return type used to match the existing code's flexibility
        return WeatherData(
          weatherIcon: icon(data['weather'][0]['id']),
          temperature: data['main']['temp'],
          humidity: data['main']['humidity'],
          windSpeed: data['wind']['speed'] * 3.6,
          rainChance: rainChanceMock,
          description: data['weather'][0]['description'],
          location: data['name'] ?? 'Current Location',
        );
      }
    } catch (_) {}

    return null;
  }

  void _handleWeatherCheck() async {
    final t = AppLocalizations.of(context)!;
    if (_currentPosition == null) {
      _showSnackBar(t.locationUnavailable, Colors.red);
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(t.fetchingWeather)));

    final weather = await _fetchWeatherDataByCoordinates(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
    );

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    if (weather != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              WeatherScreen(weather: weather, location: weather.location),
        ),
      );
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  // 🚨 NEW: SOS Logic Implementation
  void _showSosDialog(BuildContext context, AppLocalizations t) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(t.sosAlert),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(t.sosMessagePrompt),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _sosMessageController,
                  decoration: InputDecoration(
                    labelText: t.message,
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 10),
                Text(
                  '${t.yourEmail}: ${_currentUser?.email ?? t.notLoggedIn}', // Get email from FirebaseAuth
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 10),
                Text(
                  _currentPosition != null
                      ? 'Location will be shared: Lat ${_currentPosition!.latitude.toStringAsFixed(4)}, Lon ${_currentPosition!.longitude.toStringAsFixed(4)}'
                      : 'WARNING: Location is unavailable and cannot be shared.',
                  style: TextStyle(
                    fontSize: 12,
                    color: _currentPosition != null ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(t.cancel),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.warning_amber, color: Colors.white),
              label: Text(
                t.sendSos,
                style: const TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                _sendSos();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _sendSos() async {
    final t = AppLocalizations.of(context)!;
    final userEmail = _currentUser?.email;

    if (userEmail == null) {
      _showSnackBar(t.loginRequiredForSos, Colors.red);
      return;
    }

    final message = _sosMessageController.text.trim().isNotEmpty
        ? _sosMessageController.text.trim()
        : t.sosDefaultMessage;

    try {
      await _firebaseService.sendSosNotification(
        userEmail: userEmail,
        message: message,
      );

      _sosMessageController.clear();
      if (!mounted) return;
      _showSnackBar(t.sosSentSuccess, Colors.green);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(t.sosSentFailure, Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    // Language dropdown config
    final currentLocale = Localizations.localeOf(context);
    final selectedLang = currentLocale.languageCode;
    final languageMap = {"en": "English", "hi": "हिन्दी", "ta": "தமிழ்"};

    return Scaffold(
      // Drawer: Side Menu (Left)
      drawer: Drawer(
        child: Container(
          color: const Color(0xFF101010),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text(
                    'Field Officer Menu',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const Divider(color: Colors.white24),

                // 🚨 NEW: SOS Button relocated inside the Drawer (Menu Bar)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLocationAvailable && _currentUser != null
                          ? () {
                              Navigator.pop(context); // Close drawer
                              _showSosDialog(context, t);
                            }
                          : null,
                      icon: const Icon(
                        Icons.sos,
                        color: Colors.white,
                        size: 28,
                      ),
                      label: Text(
                        t.sos,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ),
                const Divider(color: Colors.white24),

                ListTile(
                  leading: const Icon(Icons.place, color: Colors.greenAccent),
                  title: Text(
                    _currentLocationName,
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    t.currentSiteLabel,
                    style: const TextStyle(color: Colors.white54),
                  ),
                ),
                const SizedBox(height: 10),
                ListTile(
                  leading: const Icon(
                    Icons.cloud_queue,
                    color: Colors.greenAccent,
                  ),
                  title: Text(
                    t.checkWeather,
                    style: const TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _handleWeatherCheck();
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.person_outline,
                    color: Colors.greenAccent,
                  ),
                  title: Text(
                    t.viewProfile,
                    style: const TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProfileScreen()),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.redAccent),
                  title: Text(
                    t.logout,
                    style: const TextStyle(color: Colors.white),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    await FirebaseService().signOut();
                    if (mounted) {
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
                const Spacer(),
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'JALNETRA v1.0',
                    style: TextStyle(color: Colors.white38),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text(t.dashboardTitleOfficer),
        actions: [
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedLang,
              dropdownColor: Colors.black87,
              icon: const Icon(Icons.language, color: Colors.white),
              style: const TextStyle(color: Colors.white),
              items: languageMap.entries
                  .map(
                    (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
                  )
                  .toList(),
              onChanged: (newLang) {
                if (newLang != null) {
                  JalNetraApp.setLocale(context, Locale(newLang));
                }
              },
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),

      body: Stack(
        children: [
          // Placeholder Map UI
          Center(
            child: Container(
              color: Colors.blueGrey.shade900,
              width: double.infinity,
              height: double.infinity,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.map, size: 80, color: Colors.white54),
                    const SizedBox(height: 10),
                    Text(
                      t.mapPlaceholder,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      t.mapPlaceholderSub,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Current location pill (like your mock)
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF202020),
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.gps_fixed,
                    color: _isLocationAvailable
                        ? const Color(0xFF4CAF50)
                        : Colors.grey,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _currentLocationName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Capture flow FAB
          Positioned(
            bottom: 30,
            left: MediaQuery.of(context).size.width / 2 - 35,
            child: SizedBox(
              height: 70,
              width: 70,
              child: FloatingActionButton(
                backgroundColor: _isLocationAvailable
                    ? Theme.of(context).primaryColor
                    : Colors.grey,
                onPressed: _isLocationAvailable
                    ? () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CaptureFlowScreen(),
                        ),
                      )
                    : null,
                child: const Icon(
                  Icons.camera_alt,
                  size: 35,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
