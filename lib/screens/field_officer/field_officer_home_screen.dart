// lib/screens/field_officer/field_officer_home_screen.dart

import 'dart:convert';

import 'package:biometric_signature/android_config.dart';
import 'package:biometric_signature/biometric_signature.dart';
import 'package:biometric_signature/ios_config.dart';
import 'package:biometric_signature/signature_options.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../../common/firebase_service.dart';
import '../../l10n/app_localizations.dart';
import '../../main.dart';
import '../common/profile_screen.dart';
import '../common/WeatherScreen.dart';
import 'capture_flow_screen.dart';
import 'field_officer_history_screen.dart';
import 'upcoming_visits_screen.dart';
import 'schedule_overview_screen.dart';
import 'kubo_chat_screen.dart'; // ⬅ make sure this path matches file below

class FieldOfficerHomeScreen extends StatefulWidget {
  const FieldOfficerHomeScreen({super.key});

  @override
  State<FieldOfficerHomeScreen> createState() => _FieldOfficerHomeScreenState();
}

class _FieldOfficerHomeScreenState extends State<FieldOfficerHomeScreen> {
  // ───────── WEATHER + LOCATION ─────────
  final String _apiKey = '567ccd2e4f1ca68963303481ce41996b';

  String _currentLocationName = "Fetching Current Site...";
  bool _isLocationAvailable = false;
  Position? _currentPosition;

  final FirebaseService _firebaseService = FirebaseService();
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  // ───────── STATS ─────────
  bool _loading = true;

  int _totalReadings = 0;
  int _todayReadings = 0;
  int _weekReadings = 0;
  int _monthReadings = 0;

  // visit / schedule stats
  int _upcomingVisitsCount = 0;
  int _monthVisitsCount = 0;

  final _firestore = FirebaseFirestore.instance;
  final _user = FirebaseAuth.instance.currentUser;

  // ───────── LOCAL THEME TOGGLER ─────────
  bool _useDarkTheme = true;

  // ───────── BIOMETRIC / FINGERPRINT ─────────
  final BiometricSignature _biometric = BiometricSignature();
  bool _biometricAuthenticated = false;
  bool _biometricBusy = false;

  @override
  void initState() {
    super.initState();
    _loadStats();
    _fetchCurrentLocationName();
  }

  // ───────────────── LOCATION / WEATHER HELPERS ─────────────────

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
        final t = AppLocalizations.of(context)!;
        setState(() {
          _currentLocationName = t.locationUnavailable;
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

  // ───────────────── STATS LOADING ─────────────────

  Future<void> _loadStats() async {
    if (_user == null) {
      setState(() => _loading = false);
      return;
    }

    setState(() => _loading = true);

    try {
      final uid = _user!.uid;
      final now = DateTime.now();

      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final weekday = now.weekday; // 1 = Monday
      final startOfWeek = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 7));

      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 1);

      final readingsRef = _firestore.collection('readings');

      final totalSnap = await readingsRef
          .where('officerId', isEqualTo: uid)
          .get();

      final todaySnap = await readingsRef
          .where('officerId', isEqualTo: uid)
          .where(
            'timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .where('timestamp', isLessThan: Timestamp.fromDate(endOfDay))
          .get();

      final weekSnap = await readingsRef
          .where('officerId', isEqualTo: uid)
          .where(
            'timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeek),
          )
          .where('timestamp', isLessThan: Timestamp.fromDate(endOfWeek))
          .get();

      final monthSnap = await readingsRef
          .where('officerId', isEqualTo: uid)
          .where(
            'timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth),
          )
          .where('timestamp', isLessThan: Timestamp.fromDate(endOfMonth))
          .get();

      // visits stats
      final visitsRef = _firestore.collection('visits');

      final upcomingSnap = await visitsRef
          .where('officerId', isEqualTo: uid)
          .where(
            'scheduledFor',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .where('status', isEqualTo: 'scheduled')
          .get();

      final monthVisitsSnap = await visitsRef
          .where('officerId', isEqualTo: uid)
          .where(
            'scheduledFor',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth),
          )
          .where('scheduledFor', isLessThan: Timestamp.fromDate(endOfMonth))
          .get();

      if (!mounted) return;

      setState(() {
        _totalReadings = totalSnap.size;
        _todayReadings = todaySnap.size;
        _weekReadings = weekSnap.size;
        _monthReadings = monthSnap.size;

        _upcomingVisitsCount = upcomingSnap.size;
        _monthVisitsCount = monthVisitsSnap.size;
      });
    } catch (e) {
      debugPrint('Error loading officer stats: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ───────────────── QUICK ACTIONS ─────────────────

  void _openNewReadingFlow() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CaptureFlowScreen()),
    );
  }

  void _openHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FieldOfficerHistoryScreen()),
    );
  }

  void _openUpcomingVisits() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const UpcomingVisitsScreen()),
    );
  }

  void _openScheduleOverview() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ScheduleOverviewScreen()),
    );
  }

  // ───────────────── BIOMETRIC AUTH ─────────────────

  Future<void> _authenticateUser() async {
    if (_biometricBusy) return;
    setState(() => _biometricBusy = true);

    try {
      final exists = await _biometric.biometricKeyExists();
      if (exists != true) {
        await _biometric.createKeys(
          androidConfig: AndroidConfig(
            signatureType: AndroidSignatureType.RSA,
            useDeviceCredentials: false,
          ),
          iosConfig: IosConfig(
            signatureType: IOSSignatureType.RSA,
            useDeviceCredentials: false,
          ),
        );
      }

      await _biometric.createSignature(
        SignatureOptions(
          payload: "auth",
          promptMessage: "Authenticate with Fingerprint",
          androidOptions: const AndroidSignatureOptions(
            subtitle: "Use fingerprint to continue",
            allowDeviceCredentials: false,
          ),
          iosOptions: const IosSignatureOptions(shouldMigrate: false),
        ),
      );

      if (mounted) {
        setState(() {
          _biometricAuthenticated = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _biometricAuthenticated = false;
        });
        _showSnackBar("Authentication Failed: $e", Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() => _biometricBusy = false);
      }
    }
  }

  Widget _buildBiometricGate(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.fingerprint,
            size: 90,
            color: isDark ? Colors.cyanAccent : Colors.deepPurple,
          ),
          const SizedBox(height: 16),
          Text(
            "Fingerprint Verification",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Only verified Field Officers can access this dashboard.",
            textAlign: TextAlign.center,
            style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _biometricBusy ? null : _authenticateUser,
            icon: _biometricBusy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.fingerprint),
            label: Text(
              _biometricBusy ? "Verifying..." : "Verify with Fingerprint",
              style: const TextStyle(fontSize: 16),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────── BUILD ─────────────────

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    final locale = Localizations.localeOf(context);
    final selectedLang = locale.languageCode;
    final languageMap = <String, String>{
      'en': 'English',
      'hi': 'हिन्दी',
      'ta': 'தமிழ்',
    };

    final isDark = _useDarkTheme;
    final Color cardBg = isDark ? const Color(0xFF181818) : Colors.white;
    final Color cardText = isDark ? Colors.white : Colors.black87;
    final Color subtitleText = isDark ? Colors.white70 : Colors.black54;
    final Color scaffoldBg = isDark
        ? const Color(0xFF101010)
        : const Color(0xFFF3F3F3);

    return Theme(
      data: isDark
          ? ThemeData.dark().copyWith(
              scaffoldBackgroundColor: scaffoldBg,
              drawerTheme: const DrawerThemeData(
                backgroundColor: Color(0xFF101010),
              ),
            )
          : ThemeData.light().copyWith(
              scaffoldBackgroundColor: scaffoldBg,
              drawerTheme: const DrawerThemeData(backgroundColor: Colors.white),
            ),
      child: Scaffold(
        drawer: Drawer(
          child: Container(
            color: isDark ? const Color(0xFF101010) : Colors.white,
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      'Field Officer Menu',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  Divider(color: isDark ? Colors.white24 : Colors.black12),
                  ListTile(
                    leading: const Icon(Icons.place, color: Colors.greenAccent),
                    title: Text(
                      _currentLocationName,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    subtitle: Text(
                      t.currentSiteLabel,
                      style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
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
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                      ),
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
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProfileScreen(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.redAccent),
                    title: Text(
                      t.logout,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    onTap: () async {
                      Navigator.pop(context); // close drawer
                      await _firebaseService.signOut();
                      if (!mounted) return;
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'JALNETRA v1.0',
                      style: TextStyle(
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
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
                      (e) =>
                          DropdownMenuItem(value: e.key, child: Text(e.value)),
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
            IconButton(
              tooltip: _useDarkTheme
                  ? 'Switch to Light Theme'
                  : 'Switch to Dark Theme',
              icon: Icon(_useDarkTheme ? Icons.dark_mode : Icons.light_mode),
              onPressed: () {
                setState(() {
                  _useDarkTheme = !_useDarkTheme;
                });
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        floatingActionButton: _biometricAuthenticated
            ? FloatingActionButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const KuboChatScreen()),
                  );
                },
                child: const Icon(Icons.chat),
              )
            : null,
        body: _biometricAuthenticated
            ? RefreshIndicator(
                onRefresh: () async {
                  await _loadStats();
                  await _fetchCurrentLocationName();
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🔼 QUICK ACTIONS MOVED TO TOP
                      Text(
                        'Quick Actions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: cardText,
                        ),
                      ),
                      const SizedBox(height: 12),
                      GridView.count(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _ActionCard(
                            icon: Icons.camera_alt_rounded,
                            title: 'New Reading',
                            subtitle: 'Capture water level',
                            bgColor: cardBg,
                            titleColor: cardText,
                            subtitleColor: subtitleText,
                            onTap: _openNewReadingFlow,
                          ),
                          _ActionCard(
                            icon: Icons.history,
                            title: 'View History',
                            subtitle:
                                'Latest ${_totalReadings.toString()} readings',
                            bgColor: cardBg,
                            titleColor: cardText,
                            subtitleColor: subtitleText,
                            onTap: _openHistory,
                          ),
                          _ActionCard(
                            icon: Icons.event_note,
                            title: 'Upcoming Visits',
                            subtitle: _upcomingVisitsCount == 0
                                ? 'No visits scheduled'
                                : '$_upcomingVisitsCount visit(s) soon',
                            bgColor: cardBg,
                            titleColor: cardText,
                            subtitleColor: subtitleText,
                            onTap: _openUpcomingVisits,
                          ),
                          _ActionCard(
                            icon: Icons.calendar_today,
                            title: 'Calendar',
                            subtitle: _monthVisitsCount == 0
                                ? 'No visits this month'
                                : '$_monthVisitsCount visit(s) this month',
                            bgColor: cardBg,
                            titleColor: cardText,
                            subtitleColor: subtitleText,
                            onTap: _openScheduleOverview,
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // 🔽 STATS GRID MOVED BELOW QUICK ACTIONS
                      Text(
                        'Reading Summary',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: cardText,
                        ),
                      ),
                      const SizedBox(height: 12),

                      if (_loading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.only(top: 20),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          children: [
                            _StatCard(
                              icon: Icons.opacity_rounded,
                              iconColor: Colors.blueAccent,
                              title: 'Total Readings',
                              value: _totalReadings.toString(),
                              bgColor: cardBg,
                              titleColor: subtitleText,
                              valueColor: cardText,
                            ),
                            _StatCard(
                              icon: Icons.event_available,
                              iconColor: Colors.green,
                              title: 'Today',
                              value: _todayReadings.toString(),
                              bgColor: cardBg,
                              titleColor: subtitleText,
                              valueColor: cardText,
                            ),
                            _StatCard(
                              icon: Icons.date_range,
                              iconColor: Colors.orange,
                              title: 'This Week',
                              value: _weekReadings.toString(),
                              bgColor: cardBg,
                              titleColor: subtitleText,
                              valueColor: cardText,
                            ),
                            _StatCard(
                              icon: Icons.calendar_month,
                              iconColor: Colors.purple,
                              title: 'This Month',
                              value: _monthReadings.toString(),
                              bgColor: cardBg,
                              titleColor: subtitleText,
                              valueColor: cardText,
                            ),
                          ],
                        ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              )
            : _buildBiometricGate(isDark),
      ),
    );
  }
}

// ───────────────── SMALL WIDGETS ─────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final Color bgColor;
  final Color titleColor;
  final Color valueColor;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.bgColor,
    required this.titleColor,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 26),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(title, style: TextStyle(fontSize: 13, color: titleColor)),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color bgColor;
  final Color titleColor;
  final Color subtitleColor;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.bgColor,
    required this.titleColor,
    required this.subtitleColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 26, color: Colors.blueAccent),
              const Spacer(),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: titleColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: subtitleColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
