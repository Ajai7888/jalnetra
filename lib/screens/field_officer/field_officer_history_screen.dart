import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/reading_model.dart';

class FieldOfficerHistoryScreen extends StatelessWidget {
  const FieldOfficerHistoryScreen({super.key});

  Stream<List<WaterReading>> _readingsStream() {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return FirebaseFirestore.instance
        .collection('readings')
        .where('officerId', isEqualTo: uid)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((doc) => WaterReading.fromFirestore(doc)).toList(),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reading History')),
      body: StreamBuilder<List<WaterReading>>(
        stream: _readingsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading history: ${snapshot.error}'),
            );
          }
          final readings = snapshot.data ?? [];
          if (readings.isEmpty) {
            return const Center(child: Text('No readings yet.'));
          }

          return ListView.separated(
            itemCount: readings.length,
            separatorBuilder: (_, __) => const Divider(height: 0),
            itemBuilder: (context, index) {
              final r = readings[index];
              final dt = r.timestamp.toLocal();
              final formatted =
                  '${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year} '
                  '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
              return ListTile(
                leading: CircleAvatar(
                  child: Text(
                    r.waterLevel.toStringAsFixed(1),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                title: Text('Site: ${r.siteId}'),
                subtitle: Text(
                  '$formatted · '
                  '${r.isManual ? 'Manual' : 'Auto'} · '
                  '${r.isVerified ? 'Verified' : 'Pending'}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // Later: you can open a details screen with image preview.
                },
              );
            },
          );
        },
      ),
    );
  }
}
