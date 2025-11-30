// lib/screens/auth/role_selection_screen.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:jalnetra01/common/firebase_service.dart';
import 'package:jalnetra01/common/loading_screen.dart';
import 'package:jalnetra01/models/user_models.dart';
import 'package:jalnetra01/screens/analyst/analyst_dashboard_screen.dart';
import 'package:jalnetra01/screens/auth/login_screen.dart';
import 'package:jalnetra01/screens/field_officer/officer_dashboard_screen.dart';
import 'package:jalnetra01/screens/supervisor/supervisor_dashboard_screen.dart';

import '../admin/admin/admin_dashboard.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  // Initialize the selected role state
  UserRole _selectedRole = UserRole.fieldOfficer;

  // --- FUNCTIONAL COLOR MAPPING ---
  // This maps the role to the primary color used for the login button and active state.
  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.fieldOfficer:
      case UserRole.supervisor:
        return const Color(0xFF3F51B5); // Deep Blue
      case UserRole.analyst:
        return Colors.green.shade600; // Green
      case UserRole.admin:
        return Colors.red.shade600; // Red
      case UserRole.publicUser:
      default:
        return Colors.white;
    }
  }

  // Function to navigate to the LoginScreen for the selected role
  void _navigateToLogin(BuildContext context, UserRole role) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen(role: role)),
    );
  }

  // Handles routing based on the user's role if they are already authenticated
  Widget _getDashboard(AppUser user) {
    switch (user.role) {
      case UserRole.fieldOfficer:
        return const OfficerDashboardScreen();
      case UserRole.supervisor:
        return const SupervisorDashboardScreen();
      case UserRole.analyst:
        return const AnalystDashboardScreen();
      case UserRole.admin:
        return const AdminHomePage();
      default:
        // Default to the unified login screen if the role is unrecognized
        return LoginScreen(role: UserRole.fieldOfficer);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseService().authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingScreen();
        }

        final user = snapshot.data;

        if (user != null) {
          // User is signed in, fetch profile data to determine routing
          return FutureBuilder<AppUser?>(
            future: FirebaseService().getUserData(user.uid),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const LoadingScreen();
              }
              if (userSnapshot.hasData && userSnapshot.data != null) {
                // Navigate to the correct dashboard based on the role
                return _getDashboard(userSnapshot.data!);
              }
              // If user is authenticated but no role data, force re-login
              FirebaseService().signOut();
              return _buildRoleSelection(context);
            },
          );
        }

        // User is signed out, show role selection UI
        return _buildRoleSelection(context);
      },
    );
  }

  Widget _buildRoleSelection(BuildContext context) {
    // Filter out publicUser from the selection list
    final selectableRoles = UserRole.values
        .where((role) => role != UserRole.publicUser)
        .toList();

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- LOGO ---
                Center(
                  child: Image.asset(
                    'assets/jalnetra_logo.png',
                    height: 150,
                    width: 150,
                    fit: BoxFit.contain,
                  ),
                ),

                const SizedBox(height: 20),

                // --- TITLE & SUBTITLE ---
                const Text(
                  'JALNETRA',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3,
                    color: Colors.blueAccent,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Smart River Water Level Monitoring',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),

                const SizedBox(height: 60),

                // --- ROLE TITLE ---
                const Text(
                  'Select Your Role to Login',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 30),

                // --- ROLE DROPDOWN ---
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white30, width: 1),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<UserRole>(
                      isExpanded: true,
                      value: _selectedRole,
                      icon: const Icon(
                        Icons.arrow_drop_down,
                        color: Colors.white,
                      ),
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      dropdownColor: Colors.black87,
                      onChanged: (UserRole? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedRole = newValue;
                          });
                        }
                      },
                      items: selectableRoles.map<DropdownMenuItem<UserRole>>((
                        UserRole role,
                      ) {
                        // Determine the color for the text inside the dropdown list:
                        // It's the functional color if the item is currently selected,
                        // otherwise, it's the requested 50% opacity white.
                        final bool isSelected = role == _selectedRole;
                        final Color itemColor = isSelected
                            ? _getRoleColor(role) // Full color if selected
                            : Colors.white.withOpacity(
                                0.50,
                              ); // 50% opacity white if not selected

                        return DropdownMenuItem<UserRole>(
                          value: role,
                          child: Text(
                            role.name.toUpperCase().replaceAll('_', ' '),
                            style: TextStyle(
                              color: itemColor, // Apply the item color here
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // --- LOGIN BUTTON ---
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      // Button background color uses the full functional color
                      backgroundColor: _getRoleColor(_selectedRole),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => _navigateToLogin(context, _selectedRole),
                    child: const Text(
                      'PROCEED TO LOGIN',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
