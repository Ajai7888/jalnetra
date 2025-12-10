// lib/models/reading_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class WaterReading {
  final String id;
  final String siteId;
  final String officerId;
  final double waterLevel;
  final String imageUrl;
  final GeoPoint location;
  final DateTime timestamp;
  final bool isVerified;
  final bool isManual;

  WaterReading({
    required this.id,
    required this.siteId,
    required this.officerId,
    required this.waterLevel,
    required this.imageUrl,
    required this.location,
    required this.timestamp,
    this.isVerified = false,
    required this.isManual,
  });

  factory WaterReading.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return WaterReading(
      id: doc.id,
      siteId: data['siteId'] ?? '',
      officerId: data['officerId'] ?? '',
      waterLevel: (data['waterLevel'] as num?)?.toDouble() ?? 0.0,
      imageUrl: data['imageUrl'] ?? '',
      location: data['location'] as GeoPoint? ?? const GeoPoint(0, 0),
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isVerified: data['isVerified'] ?? false,
      isManual: data['isManual'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'siteId': siteId,
      'officerId': officerId,
      'waterLevel': waterLevel,
      'imageUrl': imageUrl,
      'location': location,
      'timestamp': Timestamp.fromDate(timestamp),
      'isVerified': isVerified,
      'isManual': isManual,
    };
  }
}
