// lib/utils/anti_tamper_service.dart
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart';

class AntiTamperService {
  AntiTamperService._();

  /// Call this before you fetch location or submit a reading.
  static Future<bool> ensureSafeEnvironment(BuildContext context) async {
    // 1. Check permissions & location services
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showMessage(
        context,
        'Location services are disabled. Please enable and try again.',
      );
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _showMessage(
          context,
          'Location permission is required to submit readings.',
        );
        return false;
      }
    }

    // 2. (Android native / plugin) – check developer options / mock location.
    // TODO: replace these with real checks using a plugin or MethodChannel.
    final bool developerModeOn = await MethodChannel(
      'security',
    ).invokeMethod('isDeveloperModeOn');
    final bool mockLocationDetected = await MethodChannel(
      'security',
    ).invokeMethod('isMockLocationOn');

    if (developerModeOn || mockLocationDetected) {
      _showMessage(
        context,
        'High-security mode: please disable developer options or mock '
        'location apps to continue.',
      );
      return false;
    }

    // All checks passed
    return true;
  }

  static void _showMessage(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
