// lib/screens/auth/login_screen.dart

import 'package:flutter/material.dart';
import 'package:jalnetra01/common/custom_button.dart';
import 'package:jalnetra01/common/firebase_service.dart';
import 'package:jalnetra01/models/user_models.dart';
import 'package:jalnetra01/screens/analyst/analyst_dashboard_screen.dart';
import 'package:jalnetra01/screens/auth/signup_screen.dart';
import 'package:jalnetra01/screens/field_officer/officer_dashboard_screen.dart';
import 'package:jalnetra01/screens/supervisor/supervisor_dashboard_screen.dart';

import '../admin/admin/admin_dashboard.dart';

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

  String _getRoleTitle() {
    switch (widget.role) {
      case UserRole.fieldOfficer:
        return 'Field Officer Login';
      case UserRole.supervisor:
        return 'Supervisor Login';
      case UserRole.analyst:
        return 'Analyst Login';
      case UserRole.admin: // <-- NEW ADMIN TITLE
        return 'Administrator Login';
      default:
        return 'Login';
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
      case UserRole.admin: // <-- NEW ADMIN ROUTE
        destination = const AdminHomePage();
        break;
      default:
        // Should not happen if data is clean
        return;
    }

    // Check if the user's logged-in role matches the selected role
    if (user.role == widget.role) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => destination),
      );
    } else {
      _showErrorDialog(
        "Role Mismatch",
        "The logged-in user's role does not match the selected role (${widget.role.name}).",
      );
      _firebaseService.signOut(); // Force sign out on role mismatch
    }
  }

  // ... (_showErrorDialog and _handleLogin remain unchanged) ...

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: const Text('Okay'),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    final user = await _firebaseService.signIn(email, password);

    setState(() {
      _isLoading = false;
    });

    if (user != null) {
      _navigateToDashboard(user);
    } else {
      _showErrorDialog(
        "Login Failed",
        "Invalid credentials or user not found. Please try again.",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_getRoleTitle())),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email or User ID',
                prefixIcon: Icon(Icons.person_outline),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                prefixIcon: Icon(Icons.lock_outline),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 40),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : CustomButton(text: 'Login', onPressed: _handleLogin),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                // Navigate to the new sign-up screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SignUpScreen(role: widget.role),
                  ),
                );
              },
              child: const Text('Don\'t have an account? Sign Up'),
            ),
          ],
        ),
      ),
    );
  }
}
