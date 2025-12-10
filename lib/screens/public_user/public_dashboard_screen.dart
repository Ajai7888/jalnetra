// lib/screens/public_user/public_dashboard_screen.dart

import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:jalnetra01/common/firebase_service.dart';
import 'package:jalnetra01/models/user_models.dart';
import 'package:jalnetra01/screens/auth/role_selection_screen.dart';
import 'package:jalnetra01/screens/common/profile_screen.dart';
// 🔑 Use the new Public Capture Flow screen
import 'package:jalnetra01/screens/public_user/public_capture_flow_screen.dart';

// 🔥 NEW: Import the chatbot screen
import 'package:jalnetra01/screens/public_user/kubo_chat_screen.dart';

import '../../l10n/app_localizations.dart';
import '../common/WeatherScreen.dart';
import '../../../main.dart';

class PublicDashboardScreen extends StatefulWidget {
  final AppUser user; // Expecting the user object to get the email
  const PublicDashboardScreen({super.key, required this.user});

  @override
  State<PublicDashboardScreen> createState() => _PublicDashboardScreenState();
}

class _PublicDashboardScreenState extends State<PublicDashboardScreen> {
  final String _apiKey = '567ccd2e4f1ca68963303481ce41996b';

  String _currentLocationName = "Fetching Current Site...";
  bool _isLocationAvailable = false;
  Position? _currentPosition;

  final TextEditingController _sosMessageController = TextEditingController();
  final FirebaseService _firebaseService = FirebaseService();

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

  Future<dynamic> _fetchWeatherDataByCoordinates(double lat, double lon) async {
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
                  '${t.yourEmail}: ${widget.user.email}',
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
    final message = _sosMessageController.text.trim().isNotEmpty
        ? _sosMessageController.text.trim()
        : t.sosDefaultMessage;

    try {
      await _firebaseService.sendSosNotification(
        userEmail: widget.user.email,
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

    final currentLocale = Localizations.localeOf(context);
    final selectedLang = currentLocale.languageCode;
    final languageMap = {"en": "English", "hi": "हिन्दी", "ta": "தமிழ்"};

    return Scaffold(
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
                    'People Menu',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const Divider(color: Colors.white24),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed:
                          _isLocationAvailable ||
                              FirebaseAuth.instance.currentUser != null
                          ? () {
                              Navigator.pop(context);
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
                  leading: const Icon(Icons.place, color: Colors.amberAccent),
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
                    color: Colors.amberAccent,
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
                    color: Colors.amberAccent,
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
        title: Text(t.publicUserDashboard),
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
          // Map placeholder background
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

          // Current location pill
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

          // Capture flow FAB (center bottom)
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
                          builder: (_) => const PublicCaptureFlowScreen(),
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

          // 🔥 NEW: Chatbot FAB (bottom-right)
          Positioned(
            bottom: 30,
            right: 20,
            child: FloatingActionButton(
              heroTag: 'kubo_chat_fab',
              backgroundColor: Colors.deepPurple,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const KuboChatScreen()),
                );
              },
              child: const Icon(
                Icons.chat_bubble_outline,
                size: 28,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
