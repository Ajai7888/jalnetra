import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class UpcomingVisitsScreen extends StatelessWidget {
  const UpcomingVisitsScreen({super.key});

  Stream<QuerySnapshot<Map<String, dynamic>>> _visitsStream() {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    return FirebaseFirestore.instance
        .collection('visits')
        .where('officerId', isEqualTo: uid)
        .where('status', isEqualTo: 'scheduled')
        .where(
          'scheduledFor',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        )
        .orderBy('scheduledFor')
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upcoming Visits')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _visitsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading visits: ${snapshot.error}'),
            );
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No upcoming visits.'));
          }

          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 0),
            itemBuilder: (context, index) {
              final data = docs[index].data();
              final siteName = data['siteName'] ?? 'Unknown site';
              final siteId = data['siteId'] ?? '';
              final ts = data['scheduledFor'] as Timestamp;
              final dt = ts.toDate();
              final dateStr =
                  '${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year}';
              final timeStr =
                  '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

              return ListTile(
                leading: const Icon(Icons.place),
                title: Text(siteName),
                subtitle: Text('Site ID: $siteId\n$dateStr · $timeStr'),
                isThreeLine: true,
              );
            },
          );
        },
      ),
    );
  }
}
