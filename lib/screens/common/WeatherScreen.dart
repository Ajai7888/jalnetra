// lib/screens/common/weather_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class WeatherData {
  final String weatherIcon;
  final double temperature;
  final int humidity;
  final double windSpeed;
  final int rainChance;
  final String description;
  final String location;

  WeatherData({
    required this.weatherIcon,
    required this.temperature,
    required this.humidity,
    required this.windSpeed,
    required this.rainChance,
    required this.description,
    required this.location,
  });
}

class WeatherScreen extends StatelessWidget {
  final WeatherData weather;
  final String location;

  const WeatherScreen({
    super.key,
    required this.weather,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E), // Dark background
      appBar: AppBar(
        title: Text('Weather in $location'),
        backgroundColor: Colors.blueGrey,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Current Temperature and Icon ---
            Card(
              color: Colors.blueGrey.shade800,
              elevation: 5,
              child: Padding(
                padding: const EdgeInsets.all(30.0),
                child: Column(
                  children: [
                    Text(
                      weather.weatherIcon,
                      style: const TextStyle(fontSize: 60),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${weather.temperature.toStringAsFixed(0)}°C',
                      style: const TextStyle(
                        fontSize: 70,
                        fontWeight: FontWeight.w300,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      weather.description,
                      style: const TextStyle(
                        fontSize: 20,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // --- Detailed Conditions ---
            _buildWeatherDetail(
              icon: Icons.water_drop,
              label: 'Humidity',
              value: '${weather.humidity}%',
              color: Colors.cyan,
            ),
            _buildWeatherDetail(
              icon: Icons.air,
              label: 'Wind Speed',
              value: '${weather.windSpeed.toStringAsFixed(1)} km/h',
              color: Colors.lightGreen,
            ),
            _buildWeatherDetail(
              icon: Icons.umbrella,
              label: 'Rain Chance',
              value: '${weather.rainChance}%',
              color: Colors.blueAccent,
              warning: weather.rainChance > 50 ? 'Be cautious' : null,
            ),

            const SizedBox(height: 20),

            // ⭐ Button to open Flood Prediction Map
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FloodPredictionOSM()),
                );
              },
              icon: const Icon(Icons.water_damage_outlined),
              label: const Text("Open Flood Prediction Map"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.tealAccent.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherDetail({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    String? warning,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Card(
        color: const Color(0xFF121212),
        elevation: 1,
        child: ListTile(
          leading: Icon(icon, color: color, size: 30),
          title: Text(label, style: const TextStyle(color: Colors.white70)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              if (warning != null)
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Text(
                    '($warning)',
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 14,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

//
// ===============================================================
// 🟦 2️⃣ RAIN SERVICE — FETCH NEXT HOUR + NEXT 24 HOURS
// ===============================================================
//

class RainService {
  Future<Map<String, dynamic>> getRain(double lat, double lon) async {
    final url =
        "https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&hourly=precipitation&timezone=auto";

    final resp = await http.get(Uri.parse(url));
    final data = jsonDecode(resp.body);

    List times = data["hourly"]["time"];
    List rains = data["hourly"]["precipitation"];

    DateTime now = DateTime.now();
    DateTime nextHour = DateTime(now.year, now.month, now.day, now.hour + 1);
    String target = nextHour.toIso8601String().substring(0, 13);

    int idx = times.indexWhere((t) => t.startsWith(target));

    double nextHourRain = (idx != -1) ? (rains[idx] ?? 0).toDouble() : 0;

    double next24 = 0;
    for (int i = 0; i < 24 && i < rains.length; i++) {
      next24 += (rains[i] ?? 0).toDouble();
    }

    return {
      "next_hour": nextHourRain,
      "next_day": next24,
      "hourly": rains.map((e) => (e ?? 0).toDouble()).toList(),
    };
  }
}

//
// ===============================================================
// 🟧 3️⃣ HF MODEL CALL — PREDICT FUTURE WATER LEVEL (STREAM SAFE)
// ===============================================================
//

Future<double> callHFModel({
  required double rainfall,
  required double waterLevel,
  required String horizon,
}) async {
  final submitUrl = Uri.parse(
    "https://snekha21-weather-rainfall.hf.space/gradio_api/call/predict_water_level",
  );

  final submitResp = await http.post(
    submitUrl,
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({
      "data": [rainfall, waterLevel, horizon],
    }),
  );

  final submitJson = jsonDecode(submitResp.body);
  final eventId = submitJson["event_id"];

  final pollUrl = Uri.parse(
    "https://snekha21-weather-rainfall.hf.space/gradio_api/call/predict_water_level/$eventId",
  );

  while (true) {
    final resp = await http.get(pollUrl);
    final body = resp.body;

    if (body.contains("event: complete")) {
      final jsonLine = body
          .split("\n")
          .firstWhere((l) => l.startsWith("data:"), orElse: () => "")
          .replaceFirst("data:", "")
          .trim();

      if (jsonLine.isEmpty) continue;

      dynamic decoded = jsonDecode(jsonLine);

      // UNIVERSAL safety extraction:
      if (decoded is num) return decoded.toDouble();
      if (decoded is String) return double.tryParse(decoded) ?? 0;

      if (decoded is Map && decoded["data"] != null) {
        var d = decoded["data"];
        if (d is num) return d.toDouble();
        if (d is String) return double.tryParse(d) ?? 0;
        if (d is List) {
          if (d.first is num) return d.first.toDouble();
          if (d.first is String) return double.tryParse(d.first) ?? 0;
        }
      }

      if (decoded is List) {
        if (decoded.first is num) return decoded.first.toDouble();
        if (decoded.first is String) {
          return double.tryParse(decoded.first) ?? 0;
        }
      }

      throw Exception("Unexpected HF Response: $decoded");
    }

    await Future.delayed(const Duration(milliseconds: 300));
  }
}

//
// ===============================================================
// 🟨 4️⃣ FLOOD STATUS + OVERFLOW DETECTION
// ===============================================================
//

class FloodResult {
  final String status;
  final Color color;
  FloodResult(this.status, this.color);
}

FloodResult getFloodStatus(double predicted, double capacity) {
  double percent = (predicted / capacity) * 100;

  if (percent < 80) return FloodResult("Safe", Colors.green);
  if (percent < 95) return FloodResult("Warning", Colors.orange);
  return FloodResult("Critical", Colors.red);
}

/// Overflow detection logic
String checkOverflow(double predicted, double capacity) {
  if (predicted > capacity) {
    double overflowAmount = predicted - capacity;
    return "⚠ Overflow Expected by ${overflowAmount.toStringAsFixed(2)} units!";
    // units could be meters or feet based on data
  } else {
    double safeMargin = capacity - predicted;
    return "✅ Safe — ${safeMargin.toStringAsFixed(2)} units below capacity.";
  }
}

//
// ===============================================================
// 🟩 5️⃣ MAIN UI — OSM + INPUT + ML + OVERFLOW
// ===============================================================
//

class FloodPredictionOSM extends StatefulWidget {
  const FloodPredictionOSM({Key? key}) : super(key: key);

  @override
  State<FloodPredictionOSM> createState() => _FloodPredictionOSMState();
}

class _FloodPredictionOSMState extends State<FloodPredictionOSM> {
  LatLng? selectedPoint;

  final waterCtrl = TextEditingController();
  final damCtrl = TextEditingController();

  double rain1 = 0;
  double predictedWater = 0;

  FloodResult? result;
  String overflowMessage = "";

  bool loading = false;

  Future<void> calculate() async {
    if (selectedPoint == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Select a location on map")));
      return;
    }

    if (waterCtrl.text.trim().isEmpty || damCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Enter current water level & dam capacity"),
        ),
      );
      return;
    }

    setState(() => loading = true);

    double currentLevel = double.parse(waterCtrl.text.trim());
    double damCapacity = double.parse(damCtrl.text.trim());

    RainService api = RainService();
    final rain = await api.getRain(
      selectedPoint!.latitude,
      selectedPoint!.longitude,
    );

    rain1 = rain["next_hour"];

    predictedWater = await callHFModel(
      rainfall: rain1,
      waterLevel: currentLevel,
      horizon: "1hr",
    );

    result = getFloodStatus(predictedWater, damCapacity);

    overflowMessage = checkOverflow(predictedWater, damCapacity);

    setState(() => loading = false);
  }

  @override
  void dispose() {
    waterCtrl.dispose();
    damCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Flood Prediction"),
        backgroundColor: Colors.blueGrey.shade800,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // MAP
            SizedBox(
              height: 350,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(20.5937, 78.9629), // India center
                  initialZoom: 5,
                  onTap: (tapPos, latlng) {
                    setState(() => selectedPoint = latlng);
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                    userAgentPackageName: "jalnetra.app",
                  ),
                  if (selectedPoint != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: selectedPoint!,
                          child: const Icon(
                            Icons.location_on,
                            size: 40,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            if (selectedPoint != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Text(
                  "Selected: ${selectedPoint!.latitude.toStringAsFixed(4)}, "
                  "${selectedPoint!.longitude.toStringAsFixed(4)}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  TextField(
                    controller: waterCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: "Current Water Level (units)",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: damCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: "Dam Capacity (same units)",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: loading ? null : calculate,
                      child: const Text("Predict Flood Level"),
                    ),
                  ),
                ],
              ),
            ),

            if (loading) const CircularProgressIndicator(),

            if (!loading && result != null) ...[
              const SizedBox(height: 10),
              Text(
                "Rain Next Hour: ${rain1.toStringAsFixed(2)} mm",
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 10),
              Text(
                "Predicted Water Level: ${predictedWater.toStringAsFixed(2)}",
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 10),

              Text(
                overflowMessage,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: predictedWater > double.tryParse(damCtrl.text.trim())!
                      ? Colors.red
                      : Colors.green,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 15),

              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: result!.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: result!.color),
                ),
                child: Text(
                  "Status: ${result!.status}",
                  style: TextStyle(
                    color: result!.color,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ],
        ),
      ),
    );
  }
}
