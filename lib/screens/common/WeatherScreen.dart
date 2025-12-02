// lib/screens/common/weather_screen.dart (Updated)

import 'package:flutter/material.dart';

class WeatherData {
  final String weatherIcon;
  final double temperature;
  final int humidity;
  final double windSpeed;
  final int rainChance;
  final String description;
  final String location; // <--- FIX 1: ADD LOCATION FIELD HERE

  WeatherData({
    required this.weatherIcon,
    required this.temperature,
    required this.humidity,
    required this.windSpeed,
    required this.rainChance,
    required this.description,
    required this.location, // <--- FIX 2: ADD LOCATION TO CONSTRUCTOR
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
