// lib/models/capture_models.dart (NEW FILE)

import 'package:flutter/material.dart';

// DATA MODELS for Capture Flow
class QRSiteData {
  final String siteId;
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  QRSiteData({
    required this.siteId,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });
}

class SiteMetrics {
  final String name;
  final double fullTankLevelMeters;
  final double fullCapacityTMC;

  SiteMetrics({
    required this.name,
    required this.fullTankLevelMeters,
    required this.fullCapacityTMC,
  });
}

// DATA MODEL for Weather (Move from public_dashboard or weather_screen)
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
