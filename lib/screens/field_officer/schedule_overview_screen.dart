import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class ScheduleOverviewScreen extends StatefulWidget {
  const ScheduleOverviewScreen({super.key});

  @override
  State<ScheduleOverviewScreen> createState() => _ScheduleOverviewScreenState();
}

class _ScheduleOverviewScreenState extends State<ScheduleOverviewScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  Stream<QuerySnapshot<Map<String, dynamic>>> _visitsStream() {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return FirebaseFirestore.instance
        .collection('visits')
        .where('officerId', isEqualTo: uid)
        .orderBy('scheduledFor')
        .snapshots();
  }

  /// Show dialog to create a new scheduled visit for the selected day
  Future<void> _showAddVisitDialog(DateTime selectedDay) async {
    final siteNameController = TextEditingController();
    final siteIdController = TextEditingController();
    TimeOfDay? selectedTime;

    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Scheduled Visit'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Selected date: '
                    '${selectedDay.day.toString().padLeft(2, '0')}-'
                    '${selectedDay.month.toString().padLeft(2, '0')}-'
                    '${selectedDay.year}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: siteNameController,
                    decoration: const InputDecoration(
                      labelText: 'Site name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Enter site name'
                        : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: siteIdController,
                    decoration: const InputDecoration(
                      labelText: 'Site ID',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Enter site ID' : null,
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () async {
                        final now = TimeOfDay.now();
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: selectedTime ?? now,
                        );
                        if (picked != null) {
                          setState(() {
                            selectedTime = picked;
                          });
                        }
                      },
                      icon: const Icon(Icons.access_time),
                      label: Text(
                        selectedTime == null
                            ? 'Pick time'
                            : 'Time: ${selectedTime!.hour.toString().padLeft(2, '0')}:'
                                  '${selectedTime!.minute.toString().padLeft(2, '0')}',
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'If no time is chosen, 09:00 will be used by default.',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;

                final uid = FirebaseAuth.instance.currentUser!.uid;

                final time =
                    selectedTime ?? const TimeOfDay(hour: 9, minute: 0);

                final scheduledDateTime = DateTime(
                  selectedDay.year,
                  selectedDay.month,
                  selectedDay.day,
                  time.hour,
                  time.minute,
                );

                try {
                  await FirebaseFirestore.instance.collection('visits').add({
                    'officerId': uid,
                    'siteName': siteNameController.text.trim(),
                    'siteId': siteIdController.text.trim(),
                    'status': 'scheduled', // very important for Upcoming Visits
                    'scheduledFor': Timestamp.fromDate(scheduledDateTime),
                    'createdAt': FieldValue.serverTimestamp(),
                  });

                  if (mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Visit scheduled successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to schedule visit: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Visit Calendar')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddVisitDialog(_selectedDay),
        icon: const Icon(Icons.add),
        label: const Text('New visit'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _visitsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading schedule: ${snapshot.error}'),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          // Group visits by day (date-only)
          final Map<DateTime, List<QueryDocumentSnapshot<Map<String, dynamic>>>>
          visitsByDay = {};

          for (final doc in docs) {
            final data = doc.data();
            final ts = data['scheduledFor'] as Timestamp?;
            if (ts == null) continue;
            final dt = ts.toDate();
            final dayKey = DateTime(dt.year, dt.month, dt.day);

            visitsByDay.putIfAbsent(dayKey, () => []);
            visitsByDay[dayKey]!.add(doc);
          }

          List<QueryDocumentSnapshot<Map<String, dynamic>>>
          visitsForSelectedDay =
              visitsByDay[DateTime(
                _selectedDay.year,
                _selectedDay.month,
                _selectedDay.day,
              )] ??
              [];

          return Column(
            children: [
              // --- Calendar widget ---
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: TableCalendar(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2100, 12, 31),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  calendarFormat: CalendarFormat.month,
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                  eventLoader: (day) {
                    final key = DateTime(day.year, day.month, day.day);
                    return visitsByDay[key] ?? [];
                  },
                  calendarStyle: const CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: Colors.blueAccent,
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    markerDecoration: BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                  ),
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // --- Label for selected day ---
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Visits on '
                    '${_selectedDay.day.toString().padLeft(2, '0')}-'
                    '${_selectedDay.month.toString().padLeft(2, '0')}-'
                    '${_selectedDay.year}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),

              const Divider(height: 0),

              // --- List of visits for the selected day ---
              Expanded(
                child: visitsForSelectedDay.isEmpty
                    ? const Center(
                        child: Text('No visits scheduled for this day.'),
                      )
                    : ListView.separated(
                        itemCount: visitsForSelectedDay.length,
                        separatorBuilder: (_, __) => const Divider(height: 0),
                        itemBuilder: (context, index) {
                          final data = visitsForSelectedDay[index].data();
                          final siteName = data['siteName'] ?? 'Unknown site';
                          final siteId = data['siteId'] ?? '';
                          final status = data['status'] ?? 'scheduled';
                          final ts = data['scheduledFor'] as Timestamp?;
                          final dt = ts?.toDate();

                          String timeStr = '';
                          if (dt != null) {
                            timeStr =
                                '${dt.hour.toString().padLeft(2, '0')}:'
                                '${dt.minute.toString().padLeft(2, '0')}';
                          }

                          Color statusColor;
                          switch (status) {
                            case 'completed':
                              statusColor = Colors.green;
                              break;
                            case 'cancelled':
                              statusColor = Colors.red;
                              break;
                            default:
                              statusColor = Colors.orange;
                          }

                          return ListTile(
                            leading: const Icon(Icons.place),
                            title: Text(siteName),
                            subtitle: Text(
                              'Site ID: $siteId'
                              '${timeStr.isNotEmpty ? '\nTime: $timeStr' : ''}',
                            ),
                            trailing: Text(
                              status,
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            isThreeLine: true,
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
