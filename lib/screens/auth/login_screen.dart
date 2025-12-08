// lib/screens/auth/login_screen.dart (UPDATED)

import 'package:flutter/material.dart';
import 'package:jalnetra01/common/custom_button.dart';
import 'package:jalnetra01/common/firebase_service.dart';
import 'package:jalnetra01/models/user_models.dart';
import 'package:jalnetra01/screens/analyst/analyst_dashboard_screen.dart';
import 'package:jalnetra01/screens/auth/signup_screen.dart';
import 'package:jalnetra01/screens/field_officer/officer_dashboard_screen.dart';
import 'package:jalnetra01/screens/supervisor/supervisor_dashboard_screen.dart';
// 🆕 New Import
import 'package:jalnetra01/screens/public_user/public_dashboard_screen.dart';
import '../../l10n/app_localizations.dart';
import '../admin/admin/admin_dashboard.dart';
import '../../../main.dart';

class LoginScreen extends StatefulWidget {
  final UserRole role;

  const LoginScreen({super.key, required this.role});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final FirebaseService _firebaseService = FirebaseService();
  bool _isLoading = false;

  String _getRoleTitle(AppLocalizations localization) {
    switch (widget.role) {
      case UserRole.fieldOfficer:
        return localization.fieldOfficerLogin;
      case UserRole.supervisor:
        return localization.supervisorLogin;
      case UserRole.analyst:
        return localization.analystLogin;
      case UserRole.admin:
        return localization.adminLogin;
      // 🆕 New Role Title
      case UserRole.publicUser:
        return localization.publicUserLogin; // Update L10n file
      default:
        return localization.login;
    }
  }

  void _navigateToDashboard(AppUser user) {
    Widget destination;
    switch (user.role) {
      case UserRole.fieldOfficer:
        destination = const OfficerDashboardScreen();
        break;
      case UserRole.supervisor:
        destination = const SupervisorDashboardScreen();
        break;
      case UserRole.analyst:
        destination = const AnalystDashboardScreen();
        break;
      case UserRole.admin:
        destination = const AdminHomePage();
        break;
      // 🆕 New Dashboard Navigation
      case UserRole.publicUser:
        destination = PublicDashboardScreen(user: user);
        break;
      default:
        return;
    }

    // Role mismatch check
    if (user.role == widget.role) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => destination),
      );
    } else {
      final localization = AppLocalizations.of(context)!;
      _showErrorDialog(localization.roleMismatch, localization.roleMismatchMsg);
      _firebaseService.signOut();
    }
  }

  void _showErrorDialog(String title, String message) {
    final localization = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            child: Text(localization.okay),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogin() async {
    setState(() => _isLoading = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    final user = await _firebaseService.signIn(email, password);

    setState(() => _isLoading = false);

    if (user != null) {
      _navigateToDashboard(user);
    } else {
      final localization = AppLocalizations.of(context)!;
      _showErrorDialog(
        localization.loginFailed,
        localization.invalidCredentials,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;

    Locale currentLocale = Localizations.localeOf(context);
    String selectedLang = currentLocale.languageCode;
    Map<String, String> languageMap = {
      "en": "English",
      "hi": "हिन्दी",
      "ta": "தமிழ்",
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(_getRoleTitle(localization)),
        actions: [
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedLang,
              dropdownColor: Colors.black87,
              icon: const Icon(Icons.language, color: Colors.white),
              style: const TextStyle(color: Colors.white),
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
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: localization.emailOrUserId,
                prefixIcon: const Icon(Icons.person_outline),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: localization.password,
                prefixIcon: const Icon(Icons.lock_outline),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 40),

            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : CustomButton(
                    text: localization.login,
                    onPressed: _handleLogin,
                  ),

            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SignUpScreen(role: widget.role),
                  ),
                );
              },
              child: Text(localization.signupQuestion),
            ),
          ],
        ),
      ),
    );
  }
}
