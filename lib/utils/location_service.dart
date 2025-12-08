// lib/utils/location_service.dart
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'anti_tamper_service.dart';

class LocationService {
  static Future<Position?> getSecurePosition(BuildContext context) async {
    final ok = await AntiTamperService.ensureSafeEnvironment(context);
    if (!ok) return null;

    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }
}
