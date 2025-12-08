// lib/screens/common/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:jalnetra01/common/firebase_service.dart';
import 'package:jalnetra01/common/loading_screen.dart';
import 'package:jalnetra01/models/user_models.dart';

import '../../../main.dart';
import '../../l10n/app_localizations.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text(localization.profile)),
        body: Center(child: Text(localization.userNotLoggedIn)),
      );
    }

    return FutureBuilder<AppUser?>(
      future: FirebaseService().getUserData(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingScreen();
        }
        if (snapshot.hasError || snapshot.data == null) {
          return Scaffold(
            appBar: AppBar(title: Text(localization.profile)),
            body: Center(
              child: Text(
                "${localization.profileFetchError} ${snapshot.error ?? ""}",
              ),
            ),
          );
        }

        final appUser = snapshot.data!;

        Locale currentLocale = Localizations.localeOf(context);
        String selectedLang = currentLocale.languageCode;
        Map<String, String> languageMap = {
          "en": "English",
          "hi": "हिन्दी",
          "ta": "தமிழ்",
        };

        return Scaffold(
          appBar: AppBar(
            title: Text(localization.userProfile),
            actions: [
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedLang,
                  dropdownColor: Colors.black87,
                  icon: const Icon(Icons.language, color: Colors.white),
                  style: const TextStyle(color: Colors.white),
                  items: languageMap.entries.map((e) {
                    return DropdownMenuItem(value: e.key, child: Text(e.value));
                  }).toList(),
                  onChanged: (newLang) {
                    if (newLang != null) {
                      JalNetraApp.setLocale(context, Locale(newLang));
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
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
                    // Keep role in English (as you requested)
                    appUser.role.name.toUpperCase(),
                    style: TextStyle(
                      fontSize: 18,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildProfileRow(
                          Icons.mail,
                          localization.email,
                          appUser.email,
                        ),
                        _buildProfileRow(
                          Icons.badge,
                          localization.employeeId,
                          appUser.employeeId,
                        ),
                        if (appUser.phone != null)
                          _buildProfileRow(
                            Icons.phone,
                            localization.phone,
                            appUser.phone,
                          ),
                        if (appUser.department != null)
                          _buildProfileRow(
                            Icons.apartment,
                            localization.department,
                            appUser.department,
                          ),
                        if (appUser.designation != null)
                          _buildProfileRow(
                            Icons.military_tech,
                            localization.designation,
                            appUser.designation,
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(localization.editFeaturePending)),
                    );
                  },
                  icon: const Icon(Icons.edit),
                  label: Text(localization.editProfile),
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
