// lib/screens/auth/signup_screen.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:jalnetra01/common/custom_button.dart';
import 'package:jalnetra01/common/firebase_service.dart';
import 'package:jalnetra01/models/user_models.dart';
import 'package:jalnetra01/screens/auth/login_screen.dart';

class SignUpScreen extends StatefulWidget {
  final UserRole role;

  const SignUpScreen({super.key, required this.role});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _employeeIdController = TextEditingController();
  final _departmentController = TextEditingController();
  final _designationController = TextEditingController();
  final _adminCodeController = TextEditingController();

  final FirebaseService _firebaseService = FirebaseService();
  bool _isLoading = false;

  late UserRole _selectedRole;

  // ⚠️ FIX: Define the Admin Authorization Key here.
  static const String kAdminAuthCode = "JALNETRA@2025";

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.role;
  }

  // --- HELPER FUNCTION: GET TITLE BASED ON CURRENT STATE ---
  String _getRoleTitle() {
    switch (_selectedRole) {
      case UserRole.fieldOfficer:
        return 'Field Officer Registration';
      case UserRole.supervisor:
        return 'Supervisor Registration';
      case UserRole.analyst:
        return 'Analyst Registration';
      case UserRole.admin:
        return 'Administrator Registration';
      default:
        return 'User Registration';
    }
  }

  // --- HELPER FUNCTION: GET FIELD LIST BASED ON CURRENT STATE ---
  List<Map<String, dynamic>> _getRequiredFields() {
    List<Map<String, dynamic>> fields = [
      {
        'label': 'Full Name',
        'controller': _nameController,
        'keyboard': TextInputType.name,
        'icon': Icons.person,
      },
      {
        'label': 'Official Email',
        'controller': _emailController,
        'keyboard': TextInputType.emailAddress,
        'icon': Icons.email,
      },
      {
        'label': 'Password (min 6 chars)',
        'controller': _passwordController,
        'icon': Icons.lock,
        'obscure': true,
      },
      {
        'label': 'Employee ID',
        'controller': _employeeIdController,
        'keyboard': TextInputType.text,
        'icon': Icons.badge,
      },
    ];

    if (_selectedRole == UserRole.fieldOfficer) {
      fields.add({
        'label': 'Phone Number',
        'controller': _phoneController,
        'keyboard': TextInputType.phone,
        'icon': Icons.phone,
      });
      fields.add({
        'label': 'Department',
        'controller': _departmentController,
        'keyboard': TextInputType.text,
        'icon': Icons.apartment,
      });
    }

    if (_selectedRole == UserRole.supervisor) {
      fields.add({
        'label': 'Designation',
        'controller': _designationController,
        'keyboard': TextInputType.text,
        'icon': Icons.military_tech,
      });
    }

    // --- ADMIN FIELDS ---
    if (_selectedRole == UserRole.admin) {
      fields.add({
        'label': 'Admin Authorization Code',
        'controller': _adminCodeController,
        'keyboard': TextInputType.text,
        'icon': Icons.vpn_key,
        'obscure': true,
        'isSpecial': true,
      });
    }
    // --- END ADMIN FIELDS ---

    return fields;
  }

  void _showResultDialog(String title, String message, bool success) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          title,
          style: TextStyle(
            color: success ? Theme.of(context).primaryColor : Colors.red,
          ),
        ),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(ctx).pop();
              if (success) {
                // Navigate back to login screen using the ROLE THEY SIGNED UP FOR
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LoginScreen(role: _selectedRole),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // --- ADMIN CODE VALIDATION (FIXED LOGIC) ---
    if (_selectedRole == UserRole.admin) {
      // ⚠️ FIX: Check against the correct constant
      if (_adminCodeController.text.trim() != kAdminAuthCode) {
        _showResultDialog(
          "Authorization Failed",
          "Invalid Admin Code. Registration requires a valid authorization key.",
          false,
        );
        return; // Stop execution if code is wrong
      }
    }
    // --- END ADMIN CODE VALIDATION ---

    setState(() {
      _isLoading = true;
    });

    try {
      await _firebaseService.signUp(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _nameController.text.trim(),
        _selectedRole, // Use the role selected in the dropdown
        phone: _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim()
            : null,
        employeeId: _employeeIdController.text.trim().isNotEmpty
            ? _employeeIdController.text.trim()
            : null,
        department: _departmentController.text.trim().isNotEmpty
            ? _departmentController.text.trim()
            : null,
        designation: _designationController.text.trim().isNotEmpty
            ? _designationController.text.trim()
            : null,
      );

      _showResultDialog(
        "Registration Successful",
        "Your account for the ${_selectedRole.name} role has been created. Please log in.",
        true,
      );
    } on FirebaseAuthException catch (e) {
      // ... (Error handling remains unchanged) ...
      String message;
      if (e.code == 'email-already-in-use') {
        message =
            'This email is already registered. Please use the Login screen.';
      } else if (e.code == 'weak-password') {
        message = 'The password is too weak. Choose a stronger one.';
      } else {
        message = 'Registration failed: ${e.message}';
      }
      _showResultDialog("Registration Failed", message, false);
    } catch (e) {
      _showResultDialog(
        "Registration Failed",
        "An unexpected error occurred. Please try again.",
        false,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // --- UI BUILDER ---
  @override
  Widget build(BuildContext context) {
    // The UI now changes based on the internal state variable _selectedRole
    return Scaffold(
      appBar: AppBar(title: Text(_getRoleTitle())),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(
                  child: Icon(
                    Icons.person_add,
                    size: 60,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 20),
                // --- ROLE SELECTION DROPDOWN ADDED HERE ---
                _buildRoleDropdown(),
                const SizedBox(height: 20),

                Text(
                  'Registration Details for ${_selectedRole.name} Role',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 30),

                // Dynamically build form fields
                ..._getRequiredFields().map((field) {
                  // Determine if the field is required based on role
                  bool isRequired =
                      field['label'] != 'Phone Number' ||
                      _selectedRole == UserRole.fieldOfficer ||
                      field['isSpecial'] == true;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: TextFormField(
                      controller: field['controller'],
                      decoration: InputDecoration(
                        labelText: field['label'],
                        prefixIcon: Icon(field['icon']),
                      ),
                      keyboardType: field['keyboard'] ?? TextInputType.text,
                      obscureText: field['obscure'] == true,
                      validator: (value) {
                        if (isRequired && (value == null || value.isEmpty)) {
                          return '${field['label']} is required';
                        }
                        if (field['label'] == 'Official Email' &&
                            !value!.contains('@')) {
                          return 'Enter a valid email address';
                        }
                        if (field['label'] == 'Password (min 6 chars)' &&
                            value!.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        // Validation specific to the Admin Code field
                        if (field['isSpecial'] == true &&
                            value!.trim() != kAdminAuthCode &&
                            value.isNotEmpty) {
                          // This specific validation is now handled in _handleSignUp to match the error dialog
                        }
                        return null;
                      },
                    ),
                  );
                }).toList(),

                const SizedBox(height: 20),

                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : CustomButton(
                        text: 'Register Account',
                        onPressed: _handleSignUp,
                        icon: Icons.app_registration,
                      ),
                const SizedBox(height: 20),

                TextButton(
                  onPressed: () {
                    // Navigate back to login screen
                    Navigator.pop(context);
                  },
                  child: const Text('Already have an account? Back to Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- ROLE DROPDOWN WIDGET ---
  Widget _buildRoleDropdown() {
    // Filter out publicUser from the selection list
    final roles = UserRole.values
        .where((r) => r != UserRole.publicUser)
        .toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white30, width: 1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<UserRole>(
          isExpanded: true,
          value: _selectedRole,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
          style: const TextStyle(fontSize: 16, color: Colors.white),
          dropdownColor: Colors.grey.shade900,
          onChanged: (UserRole? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedRole = newValue;
                // Clear dynamic controllers when role changes to avoid misvalidation
                _phoneController.clear();
                _departmentController.clear();
                _designationController.clear();
                _adminCodeController.clear();
              });
            }
          },
          items: roles.map<DropdownMenuItem<UserRole>>((UserRole role) {
            return DropdownMenuItem<UserRole>(
              value: role,
              child: Text(
                role.name.toUpperCase().replaceAll('_', ' '),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _employeeIdController.dispose();
    _departmentController.dispose();
    _designationController.dispose();
    _adminCodeController.dispose(); // <-- DISPOSE NEW CONTROLLER
    super.dispose();
  }
}
