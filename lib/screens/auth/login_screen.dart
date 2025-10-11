import 'package:flutter/material.dart';
import 'package:jalnetra01/models/user_models.dart';
import 'package:jalnetra01/screens/analyst/analyst_dashboard_screen.dart';
import 'package:jalnetra01/screens/field_officer/officer_dashboard_screen.dart';
import 'package:jalnetra01/screens/supervisor/supervisor_dashboard_screen.dart';

class LoginScreen extends StatelessWidget {
  final UserRole role;

  const LoginScreen({super.key, required this.role});

  String _getRoleTitle() {
    switch (role) {
      case UserRole.fieldOfficer:
        return 'Field Officer Login';
      case UserRole.supervisor:
        return 'Supervisor Login';
      case UserRole.analyst:
        return 'Analyst Login';
    }
  }

  void _handleLogin(BuildContext context) {
    // Mock login logic
    Widget destination;
    switch (role) {
      case UserRole.fieldOfficer:
        destination = const OfficerDashboardScreen();
        break;
      case UserRole.supervisor:
        destination = const SupervisorDashboardScreen();
        break;
      case UserRole.analyst:
        destination = const JalnetraDashboard();
        break;
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => destination),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getRoleTitle()),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Email or User ID',
                prefixIcon: Icon(Icons.person_outline),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Password',
                prefixIcon: Icon(Icons.lock_outline),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => _handleLogin(context),
              child: const Text('Login'),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                // Handle sign up navigation
              },
              child: const Text('Don\'t have an account? Sign Up'),
            )
          ],
        ),
      ),
    );
  }
}