// lib/screens/admin/admin_dashboard.dart

import 'package:flutter/material.dart';
import 'package:jalnetra01/common/firebase_service.dart';
import 'package:jalnetra01/models/user_models.dart';
import 'package:jalnetra01/common/loading_screen.dart';

import '../../common/profile_screen.dart';

// ------------------------------------------------------
// THEME COLORS (for consistency with the Admin UI design)
// ------------------------------------------------------
const Color appGreen = Color(0xFF00A74A);
const Color backgroundDark = Color(0xFF121212);
const Color cardBackground = Color(0xFF1E1E1E);

//======================================================
// 1️⃣ ADMIN HOME PAGE
//======================================================

class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Using a dark green color for the AppBar only on the home page for contrast
        backgroundColor: const Color.fromARGB(255, 0, 13, 6),
        title: const Text("Admin Dashboard"),
        actions: [
          // 1. Profile Icon (Navigate to ProfileScreen)
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'View Profile',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
          // 2. Logout Button
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await FirebaseService().signOut();
              // Navigate back to role selection screen after logout
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    // NOTE: Assuming RoleSelectionScreen is available in the main app structure
                    builder: (_) =>
                        const Text('Placeholder for RoleSelectionScreen'),
                  ),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Welcome Card/Summary ---
            const Padding(
              padding: EdgeInsets.only(bottom: 20.0),
              child: Text(
                "System Management Overview",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),

            // --- Navigation Buttons ---
            adminButton(
              context,
              title: "Supervisors",
              icon: Icons.manage_accounts,
              page: const SupervisorPage(),
            ),
            const SizedBox(height: 20),
            adminButton(
              context,
              title: "Field Officers",
              icon: Icons.engineering,
              page: const FieldOfficerPage(),
            ),
            const SizedBox(height: 20),
            adminButton(
              context,
              title: "Analysts",
              icon: Icons.analytics,
              page: const AnalystPage(),
            ),
            const SizedBox(height: 20),
            adminButton(
              context,
              title: "Alerts & Incidents",
              icon: Icons.notifications_active,
              page: const AlertsPage(),
            ),
            const SizedBox(height: 20),
            adminButton(
              context,
              title: "Pending Approvals",
              icon: Icons.check_circle_outline,
              page: const UserApprovalPage(),
              color: Colors.orange.shade700, // Highlight this button
            ),
          ],
        ),
      ),
    );
  }

  Widget adminButton(
    BuildContext context, {
    required String title,
    required IconData icon,
    Widget? page,
    VoidCallback? onTap,
    Color color = appGreen,
  }) {
    final navTap =
        onTap ??
        (page != null
            ? () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => page!),
              )
            : () {});

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // FIX: Wrap the icon and text in Expanded to push the button correctly
          Expanded(
            child: Row(
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(width: 15),
                // Wrap title text in Expanded to ensure it shrinks
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 18, color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          // FIX: Add the required onPressed parameter
          ElevatedButton(
            onPressed: navTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              "View Details",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

//======================================================
// 2️⃣ SUPERVISOR PAGE (Firebase Integrated)
//======================================================

class SupervisorPage extends StatelessWidget {
  const SupervisorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: appGreen,
        title: const Text("Supervisors"),
      ),
      body: StreamBuilder<List<AppUser>>(
        stream: FirebaseService().getUsersByRole(UserRole.supervisor),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingScreen();
          }
          // The error "cloud_firestore/permission-denied" must be fixed
          // by updating Firestore Rules to allow 'list' access for admins.
          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error fetching data: ${snapshot.error}",
                style: const TextStyle(color: Colors.red),
              ),
            );
          }
          final users = snapshot.data ?? [];

          if (users.isEmpty) {
            return const Center(
              child: Text(
                "No supervisors registered.",
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: users
                .map(
                  (user) => OfficerTile(
                    key: ValueKey(user.id),
                    name: user.name,
                    siteId:
                        user.designation ??
                        'N/A', // Use Designation for siteId placeholder
                    officerId: user.employeeId ?? 'N/A',
                    showRemoveButton: true,
                    // FIX: Pass the Firestore UID for removal
                    userId: user.id,
                  ),
                )
                .toList(),
          );
        },
      ),
    );
  }
}

//======================================================
// 3️⃣ FIELD OFFICER PAGE (Firebase Integrated)
//======================================================

class FieldOfficerPage extends StatelessWidget {
  const FieldOfficerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: appGreen,
        title: const Text("Field Officers"),
      ),
      body: StreamBuilder<List<AppUser>>(
        stream: FirebaseService().getUsersByRole(UserRole.fieldOfficer),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingScreen();
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error fetching data: ${snapshot.error}",
                style: const TextStyle(color: Colors.red),
              ),
            );
          }
          final users = snapshot.data ?? [];

          if (users.isEmpty) {
            return const Center(
              child: Text(
                "No field officers registered.",
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: users
                .map(
                  (user) => OfficerTile(
                    key: ValueKey(user.id),
                    name: user.name,
                    siteId:
                        user.department ??
                        'N/A', // Use Department for siteId placeholder
                    officerId: user.employeeId ?? 'N/A',
                    showRemoveButton: true,
                    // FIX: Pass the Firestore UID for removal
                    userId: user.id,
                  ),
                )
                .toList(),
          );
        },
      ),
    );
  }
}

//======================================================
// 4️⃣ ANALYST PAGE (Firebase Integrated)
//======================================================

class AnalystPage extends StatelessWidget {
  const AnalystPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: appGreen, title: const Text("Analysts")),
      body: StreamBuilder<List<AppUser>>(
        stream: FirebaseService().getUsersByRole(UserRole.analyst),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingScreen();
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error fetching data: ${snapshot.error}",
                style: const TextStyle(color: Colors.red),
              ),
            );
          }
          final users = snapshot.data ?? [];

          if (users.isEmpty) {
            return const Center(
              child: Text(
                "No analysts registered.",
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: users
                .map(
                  (user) => AnalystTile(
                    key: ValueKey(user.id),
                    name: user.name,
                    analystId: user.employeeId ?? 'N/A',
                    region:
                        user.designation ??
                        'N/A', // Using Designation as region placeholder
                    showRemoveButton: true,
                    // FIX: Pass the Firestore UID for removal
                    userId: user.id,
                  ),
                )
                .toList(),
          );
        },
      ),
    );
  }
}

//======================================================
// 5️⃣ USER APPROVAL PAGE (New Feature)
//======================================================

class UserApprovalPage extends StatelessWidget {
  const UserApprovalPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange.shade700,
        title: const Text("Pending User Approvals"),
      ),
      body: StreamBuilder<List<AppUser>>(
        stream: FirebaseService().getUnverifiedUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingScreen();
          }
          if (snapshot.hasError || snapshot.data == null) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          final users = snapshot.data!;

          if (users.isEmpty) {
            return const Center(child: Text("No accounts require approval."));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: users
                .map((user) => ApprovalTile(key: ValueKey(user.id), user: user))
                .toList(),
          );
        },
      ),
    );
  }
}

//======================================================
// 6️⃣ ALERTS PAGE (CARDS - MOCK)
//======================================================

class AlertsPage extends StatelessWidget {
  const AlertsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: appGreen,
        title: const Text("Alerts Overview"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            "Live System Incidents:",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 10),
          OverviewTile(
            icon: Icons.dangerous_rounded,
            title: "High Alerts",
            value: "12",
            color: Colors.red,
            onTap: () {}, // Placeholder for navigation
          ),
          OverviewTile(
            icon: Icons.warning_rounded,
            title: "Medium Alerts",
            value: "35",
            color: Colors.orange,
            onTap: () {},
          ),
          OverviewTile(
            icon: Icons.info_outline_rounded,
            title: "Low Alerts",
            value: "61",
            color: Colors.blue,
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

//======================================================
// 🔁 REUSABLE TILE WIDGETS
//======================================================

class OfficerTile extends StatelessWidget {
  final String name;
  final String siteId; // Used for Department/Designation display
  final String officerId; // Used for Employee ID display
  final bool showRemoveButton;
  final String userId; // Added required parameter

  const OfficerTile({
    super.key,
    required this.name,
    required this.siteId,
    required this.officerId,
    this.showRemoveButton = false,
    required this.userId, // Added required parameter
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 25,
            backgroundColor: Colors.white24,
            child: Icon(Icons.person, color: Colors.white),
          ),
          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Role Detail: $siteId",
                  style: const TextStyle(color: Colors.white70),
                ),
                Text(
                  "Emp ID: $officerId",
                  style: const TextStyle(color: Colors.white70),
                ),
                Text(
                  "UID: ${userId.substring(0, 8)}...",
                  style: const TextStyle(color: Colors.white54, fontSize: 10),
                ),
              ],
            ),
          ),

          if (showRemoveButton)
            ElevatedButton(
              onPressed: () {
                // Admin removal logic: Use the Firebase UID for deletion
                FirebaseService().removeUser(userId);
              },
              style: ElevatedButton.styleFrom(backgroundColor: appGreen),
              child: const Text(
                "Remove",
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}

class AnalystTile extends StatelessWidget {
  final String name;
  final String analystId; // Used for Employee ID display
  final String region; // Used for Region/Designation display
  final bool showRemoveButton;
  final String userId; // Added required parameter

  const AnalystTile({
    super.key,
    required this.name,
    required this.analystId,
    required this.region,
    this.showRemoveButton = false,
    required this.userId, // Added required parameter
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 25,
            backgroundColor: Colors.white24,
            child: Icon(Icons.person, color: Colors.white),
          ),
          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Analyst ID: $analystId",
                  style: const TextStyle(color: Colors.white70),
                ),
                Text(
                  "Region/Designation: $region",
                  style: const TextStyle(color: Colors.white70),
                ),
                Text(
                  "UID: ${userId.substring(0, 8)}...",
                  style: const TextStyle(color: Colors.white54, fontSize: 10),
                ),
              ],
            ),
          ),

          if (showRemoveButton)
            ElevatedButton(
              onPressed: () {
                // Admin removal logic: Use the Firebase UID for deletion
                FirebaseService().removeUser(userId);
              },
              style: ElevatedButton.styleFrom(backgroundColor: appGreen),
              child: const Text(
                "Remove",
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}

class OverviewTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;
  final VoidCallback onTap;

  const OverviewTile({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    required this.onTap, // Added required onTap
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: cardBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: color.withOpacity(0.2),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            // Optionally add an arrow or button here for navigation
            Icon(Icons.arrow_forward_ios, size: 16, color: color),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------
// NEW TILE: USER APPROVAL TILE
// ------------------------------------------------------

class ApprovalTile extends StatelessWidget {
  final AppUser user;

  const ApprovalTile({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    // Determine the role string
    final roleString = user.role.toString().split('.').last;

    // Determine the role color
    Color roleColor;
    switch (user.role) {
      case UserRole.supervisor:
        roleColor = Colors.blue;
        break;
      case UserRole.fieldOfficer:
        roleColor = appGreen;
        break;
      case UserRole.analyst:
        roleColor = Colors.purple;
        break;
      default:
        roleColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: roleColor.withOpacity(0.2),
                child: Icon(Icons.person_add, color: roleColor, size: 20),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Role Requested: ${roleString.toUpperCase()}',
                      style: TextStyle(color: roleColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white12, height: 20),
          Text(
            'Email: ${user.email}',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          Text(
            'Emp ID: ${user.employeeId}',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),

          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  // Reject/Delete logic
                  FirebaseService().removeUser(user.id);
                },
                child: const Text(
                  'REJECT',
                  style: TextStyle(color: Colors.red),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  // Approve logic: Set isAccountVerified to true
                  FirebaseService().updateUserRole(user.id, user.role, true);
                },
                style: ElevatedButton.styleFrom(backgroundColor: appGreen),
                child: const Text(
                  'APPROVE',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
