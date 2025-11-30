import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:jalnetra01/common/firebase_service.dart';
import 'package:jalnetra01/common/loading_screen.dart';
import 'package:jalnetra01/models/user_models.dart';
import 'package:jalnetra01/models/reading_model.dart';

class SupervisorProfileScreen extends StatelessWidget {
  const SupervisorProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Supervisor Profile')),
        body: const Center(child: Text('User not logged in.')),
      );
    }

    // Fetch detailed supervisor profile from Firestore
    return FutureBuilder<AppUser?>(
      future: FirebaseService().getUserData(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingScreen();
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Supervisor Profile')),
            body: Center(
              child: Text(
                "Error fetching user data: "
                "${snapshot.error ?? 'Profile missing.'}",
              ),
            ),
          );
        }

        final appUser = snapshot.data!;

        return Scaffold(
          appBar: AppBar(title: const Text('Supervisor Profile')),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Avatar + name + role
                const Center(
                  child: CircleAvatar(
                    radius: 50,
                    child: Icon(Icons.supervisor_account, size: 70),
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Text(
                    appUser.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    'SUPERVISOR',
                    style: TextStyle(
                      fontSize: 18,
                      color: Theme.of(context).primaryColor,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // Detailed info card (same style as common profile)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildProfileRow(Icons.mail, "Email", appUser.email),
                        _buildProfileRow(
                          Icons.badge,
                          "Employee ID",
                          appUser.employeeId,
                        ),
                        if (appUser.phone != null)
                          _buildProfileRow(Icons.phone, "Phone", appUser.phone),
                        if (appUser.department != null)
                          _buildProfileRow(
                            Icons.apartment,
                            "Department",
                            appUser.department,
                          ),
                        if (appUser.designation != null)
                          _buildProfileRow(
                            Icons.military_tech,
                            "Designation",
                            appUser.designation,
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Supervisor stats card (pending / verified readings)
                _buildSupervisorStatsCard(),

                const SizedBox(height: 20),

                ElevatedButton.icon(
                  onPressed: () {
                    // Placeholder for edit feature
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Profile edit feature coming soon.'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit Profile'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------- Helper: single row (icon + title + value) ----------

  Widget _buildProfileRow(IconData icon, String title, String? value) {
    if (value == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey, size: 20),
          const SizedBox(width: 15),
          Expanded(
            flex: 2,
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.white70,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Supervisor-specific stats card ----------

  Widget _buildSupervisorStatsCard() {
    final service = FirebaseService();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "VERIFICATION SUMMARY",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Pending verifications
            StreamBuilder<List<WaterReading>>(
              stream: service.getPendingVerifications(),
              builder: (context, snapshot) {
                final pendingCount = snapshot.data?.length ?? 0;
                return _buildStatChip(
                  icon: Icons.hourglass_top,
                  label: "Pending verifications",
                  value: pendingCount.toString(),
                  color: Colors.orange,
                );
              },
            ),
            const SizedBox(height: 8),

            // Verified readings
            StreamBuilder<List<WaterReading>>(
              stream: service.getAllVerifiedReadings(),
              builder: (context, snapshot) {
                final verifiedCount = snapshot.data?.length ?? 0;
                return _buildStatChip(
                  icon: Icons.verified,
                  label: "Verified readings",
                  value: verifiedCount.toString(),
                  color: Colors.green,
                );
              },
            ),
            const SizedBox(height: 8),

            // Placeholder for future metric
            _buildStatChip(
              icon: Icons.warning_amber_rounded,
              label: "Critical alerts handled",
              value: "—",
              color: Colors.redAccent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: color.withOpacity(0.15),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label, style: const TextStyle(color: Colors.white70)),
        ),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}
