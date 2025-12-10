// lib/screens/auth/role_selection_screen.dart (UPDATED)

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:jalnetra01/common/firebase_service.dart';
import 'package:jalnetra01/common/loading_screen.dart';
import 'package:jalnetra01/models/user_models.dart';
import 'package:jalnetra01/screens/analyst/analyst_dashboard_screen.dart';
import 'package:jalnetra01/screens/auth/login_screen.dart';
import 'package:jalnetra01/screens/field_officer/officer_dashboard_screen.dart';
import 'package:jalnetra01/screens/supervisor/supervisor_dashboard_screen.dart';
import 'package:jalnetra01/screens/admin/admin/admin_dashboard.dart';
// 🆕 New Import
import 'package:jalnetra01/screens/public_user/public_dashboard_screen.dart';

import '../../l10n/app_localizations.dart';
import '../../../main.dart';
import '../field_officer/field_officer_home_screen.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  // Set default to Public User (People) for easier access
  UserRole _selectedRole = UserRole.publicUser;

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.fieldOfficer:
      case UserRole.supervisor:
        return const Color(0xFF3F51B5);
      case UserRole.analyst:
        return Colors.green;
      case UserRole.admin:
        return Colors.red;
      // 🆕 New Role Color
      case UserRole.publicUser:
        return Colors.amber.shade700;
      default:
        return Colors.white;
    }
  }

  void _navigateToLogin(BuildContext context, UserRole role) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen(role: role)),
    );
  }

  Widget _getDashboard(AppUser user) {
    switch (user.role) {
      case UserRole.fieldOfficer:
        return const FieldOfficerHomeScreen();
      case UserRole.supervisor:
        return const SupervisorDashboardScreen();
      case UserRole.analyst:
        return const AnalystDashboardScreen();
      case UserRole.admin:
        return const AdminHomePage();
      // 🆕 New Dashboard Route
      case UserRole.publicUser:
        return PublicDashboardScreen(user: user);
      default:
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
          return FutureBuilder<AppUser?>(
            future: FirebaseService().getUserData(user.uid),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const LoadingScreen();
              }
              if (userSnapshot.hasData && userSnapshot.data != null) {
                return _getDashboard(userSnapshot.data!);
              }
              FirebaseService().signOut();
              return _buildRoleSelection(context);
            },
          );
        }

        return _buildRoleSelection(context);
      },
    );
  }

  Widget _buildRoleSelection(BuildContext context) {
    // 🆕 Now include all roles, including publicUser
    final selectableRoles = UserRole.values.toList();

    final localization = AppLocalizations.of(context)!;

    Locale currentLocale = Localizations.localeOf(context);
    String selectedLanguage = currentLocale.languageCode;

    Map<String, String> languageMap = {
      "en": "English",
      "hi": "हिन्दी",
      "ta": "தமிழ்",
    };

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // -------------------------------------------------
                // 🔥 Top bar with language selector dropdown
                // -------------------------------------------------
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white30),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedLanguage,
                        dropdownColor: Colors.black87,
                        icon: const Icon(Icons.language, color: Colors.white),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        items: languageMap.entries.map((entry) {
                          return DropdownMenuItem<String>(
                            value: entry.key,
                            child: Text(entry.value),
                          );
                        }).toList(),
                        onChanged: (newLang) {
                          if (newLang != null) {
                            JalNetraApp.setLocale(context, Locale(newLang));
                          }
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 25),

                Center(
                  child: Image.asset(
                    'assets/jalnetra_logo.png',
                    height: 150,
                    width: 150,
                  ),
                ),
                const SizedBox(height: 20),

                // Title
                Text(
                  localization.appName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3,
                    color: Colors.blueAccent,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  localization.tagline,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.white70),
                ),
                const SizedBox(height: 60),

                Text(
                  localization.roleSelectionTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 30),

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
                      dropdownColor: Colors.black87,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      onChanged: (newValue) {
                        if (newValue != null) {
                          setState(() => _selectedRole = newValue);
                        }
                      },
                      items: selectableRoles.map((role) {
                        final isSelected = role == _selectedRole;
                        return DropdownMenuItem(
                          value: role,
                          child: Text(
                            // 🆕 Display Public User as 'People'
                            role == UserRole.publicUser
                                ? 'PEOPLE'
                                : role.name.toUpperCase().replaceAll('_', ' '),
                            style: TextStyle(
                              color: isSelected
                                  ? _getRoleColor(role)
                                  : Colors.white.withOpacity(0.5),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _getRoleColor(_selectedRole),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => _navigateToLogin(context, _selectedRole),
                    child: Text(
                      localization.proceedToLogin,
                      style: const TextStyle(
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

  Widget _langButton(String label, Locale locale) {
    return GestureDetector(
      onTap: () => JalNetraApp.setLocale(context, locale),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white38),
        ),
        child: Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ),
    );
  }
}
