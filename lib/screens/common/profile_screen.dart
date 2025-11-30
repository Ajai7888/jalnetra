// lib/screens/common/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:jalnetra01/common/firebase_service.dart';
import 'package:jalnetra01/common/loading_screen.dart';
import 'package:jalnetra01/models/user_models.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: Text("User not logged in.")),
      );
    }

    // Fetch the detailed profile data from Firestore
    return FutureBuilder<AppUser?>(
      future: FirebaseService().getUserData(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingScreen();
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Profile')),
            body: Center(
              child: Text(
                "Error fetching user data: ${snapshot.error ?? 'Profile missing.'}",
              ),
            ),
          );
        }

        final appUser = snapshot.data!;

        return Scaffold(
          appBar: AppBar(title: const Text('User Profile')),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(
                  child: CircleAvatar(
                    radius: 50,
                    child: Icon(Icons.account_circle, size: 70),
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
                    appUser.role.toString().split('.').last.toUpperCase(),
                    style: TextStyle(
                      fontSize: 18,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // Detailed Information Card
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
                ElevatedButton.icon(
                  onPressed: () {
                    // Placeholder for edit functionality
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
}
