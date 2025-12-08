// lib/screens/auth/signup_screen.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:jalnetra01/common/custom_button.dart';
import 'package:jalnetra01/common/firebase_service.dart';
import 'package:jalnetra01/models/user_models.dart';
import 'package:jalnetra01/screens/auth/login_screen.dart';
import 'package:jalnetra01/main.dart';

import '../../l10n/app_localizations.dart';

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

  static const String kAdminAuthCode = "JALNETRA@2025";

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.role;
  }

  // 1. UPDATED: Add Public User title
  String _getRoleTitle(AppLocalizations t) {
    switch (_selectedRole) {
      case UserRole.fieldOfficer:
        return t.fieldOfficerRegistration;
      case UserRole.supervisor:
        return t.supervisorRegistration;
      case UserRole.analyst:
        return t.analystRegistration;
      case UserRole.admin:
        return t.adminRegistration;
      case UserRole.publicUser: // 🆕 Handle Public User
        // You must have 'publicUserRegistration' in your .arb files
        return t.publicUserRegistration;
      default:
        return t.registrationSuccessful;
    }
  }

  // 2. UPDATED: Conditional fields for Public User
  List<Map<String, dynamic>> _getRequiredFields(AppLocalizations t) {
    final fields = <Map<String, dynamic>>[
      {
        'label': t.fullName,
        'controller': _nameController,
        'keyboard': TextInputType.name,
        'icon': Icons.person,
      },
      {
        'label': t.officialEmail, // Using officialEmail label for simplicity
        'controller': _emailController,
        'keyboard': TextInputType.emailAddress,
        'icon': Icons.email,
      },
      {
        'label': t.passwordMin,
        'controller': _passwordController,
        'keyboard': TextInputType.text,
        'icon': Icons.lock,
        'obscure': true,
      },
    ];

    // Fields for Field Officer AND Public User (People)
    if (_selectedRole == UserRole.fieldOfficer ||
        _selectedRole == UserRole.publicUser) {
      fields.add({
        'label': t.phoneNumber,
        'controller': _phoneController,
        'keyboard': TextInputType.phone,
        'icon': Icons.phone,
      });
    }

    // Fields for all staff roles (non-public)
    if (_selectedRole != UserRole.publicUser) {
      fields.add({
        'label': t.employeeId,
        'controller': _employeeIdController,
        'keyboard': TextInputType.text,
        'icon': Icons.badge,
      });
    }

    if (_selectedRole == UserRole.fieldOfficer) {
      fields.add({
        'label': t.department,
        'controller': _departmentController,
        'keyboard': TextInputType.text,
        'icon': Icons.apartment,
      });
    }

    if (_selectedRole == UserRole.supervisor) {
      fields.add({
        'label': t.designation,
        'controller': _designationController,
        'keyboard': TextInputType.text,
        'icon': Icons.military_tech,
      });
    }

    if (_selectedRole == UserRole.admin) {
      fields.add({
        'label': t.adminCode,
        'controller': _adminCodeController,
        'keyboard': TextInputType.text,
        'icon': Icons.vpn_key,
        'obscure': true,
        'isSpecial': true,
      });
    }

    return fields;
  }

  void _showResultDialog(String title, String message, bool success) {
    final t = AppLocalizations.of(context)!;

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
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              if (success) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LoginScreen(role: _selectedRole),
                  ),
                );
              }
            },
            child: Text(t.okay),
          ),
        ],
      ),
    );
  }

  // 3. UPDATED: Conditional fields in _handleSignUp
  Future<void> _handleSignUp() async {
    final t = AppLocalizations.of(context)!;

    if (!_formKey.currentState!.validate()) return;

    if (_selectedRole == UserRole.admin) {
      if (_adminCodeController.text.trim() != kAdminAuthCode) {
        _showResultDialog(t.authorizationFailed, t.invalidAdminCode, false);
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      await _firebaseService.signUp(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _nameController.text.trim(),
        _selectedRole,
        // Public User and Field Officer need phone
        phone:
            (_selectedRole == UserRole.publicUser ||
                _selectedRole == UserRole.fieldOfficer)
            ? _phoneController.text.trim()
            : null,
        // Staff roles need employeeId (Public User should pass null/empty)
        employeeId: _selectedRole != UserRole.publicUser
            ? _employeeIdController.text.trim()
            : null,
        // Department only for Field Officer
        department: _selectedRole == UserRole.fieldOfficer
            ? _departmentController.text.trim()
            : null,
        // Designation only for Supervisor
        designation: _selectedRole == UserRole.supervisor
            ? _designationController.text.trim()
            : null,
      );

      _showResultDialog(
        t.registrationSuccessful,
        // Use 'People' for display when role is publicUser
        t.accountCreatedMsg(
          _selectedRole == UserRole.publicUser ? 'People' : _selectedRole.name,
        ),
        true,
      );
    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'email-already-in-use') {
        message = t.emailInUse;
      } else if (e.code == 'weak-password') {
        message = t.weakPassword;
      } else {
        message = '${t.registrationFailed}: ${e.message}';
      }
      _showResultDialog(t.registrationFailed, message, false);
    } catch (_) {
      _showResultDialog(t.registrationFailed, t.unexpectedError, false);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final selectedLang = locale.languageCode;

    final languageMap = <String, String>{
      'en': 'English',
      'hi': 'हिन्दी',
      'ta': 'தமிழ்',
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(_getRoleTitle(t)),
        actions: [
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedLang,
              dropdownColor: Colors.black87,
              icon: const Icon(Icons.language, color: Colors.white),
              style: const TextStyle(color: Colors.white),
              items: languageMap.entries
                  .map(
                    (e) => DropdownMenuItem<String>(
                      value: e.key,
                      child: Text(e.value),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  JalNetraApp.setLocale(context, Locale(value));
                }
              },
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const Icon(Icons.person_add, size: 60, color: Colors.white70),
                const SizedBox(height: 20),
                _buildRoleDropdown(t),
                const SizedBox(height: 20),
                Text(
                  // Use 'People' for display when role is publicUser
                  t.registrationDetails(
                    _selectedRole == UserRole.publicUser
                        ? 'People'
                        : _selectedRole.name,
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 30),
                ..._getRequiredFields(t).map((field) {
                  final label = field['label'] as String;
                  final controller =
                      field['controller'] as TextEditingController;
                  final icon = field['icon'] as IconData;
                  final keyboard = field['keyboard'] as TextInputType?;
                  final obscure = field['obscure'] == true;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: TextFormField(
                      controller: controller,
                      decoration: InputDecoration(
                        labelText: label,
                        prefixIcon: Icon(icon),
                      ),
                      keyboardType: keyboard ?? TextInputType.text,
                      obscureText: obscure,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '$label is required';
                        }
                        if (label == t.officialEmail && !value.contains('@')) {
                          return 'Enter a valid email address';
                        }
                        if (label == t.passwordMin && value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        // Basic phone number validation for Field Officer and People
                        if (label == t.phoneNumber &&
                            (_selectedRole == UserRole.publicUser ||
                                _selectedRole == UserRole.fieldOfficer)) {
                          if (!RegExp(
                            r'^\d{10}$',
                          ).hasMatch(value.replaceAll(RegExp(r'[\s\-]'), ''))) {
                            return 'Enter a valid 10-digit phone number';
                          }
                        }
                        return null;
                      },
                    ),
                  );
                }).toList(),
                const SizedBox(height: 20),
                _isLoading
                    ? const CircularProgressIndicator()
                    : CustomButton(
                        text: t.registerAccount,
                        icon: Icons.app_registration,
                        onPressed: _handleSignUp,
                      ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(t.backToLogin),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 4. UPDATED: Include Public User in the dropdown and rename it to 'PEOPLE'
  Widget _buildRoleDropdown(AppLocalizations t) {
    // Include all roles this time
    final roles = UserRole.values.toList();

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
          dropdownColor: Colors.grey.shade900,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
          style: const TextStyle(fontSize: 16, color: Colors.white),
          items: roles.map((role) {
            return DropdownMenuItem<UserRole>(
              value: role,
              child: Text(
                role == UserRole.publicUser
                    ? 'PEOPLE' // 🆕 Display name for public user
                    : role.name.toUpperCase().replaceAll('_', ' '),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            );
          }).toList(),
          onChanged: (newValue) {
            if (newValue != null) {
              setState(() {
                _selectedRole = newValue;
                // Clear non-relevant fields when role changes
                _phoneController.clear();
                _employeeIdController.clear();
                _departmentController.clear();
                _designationController.clear();
                _adminCodeController.clear();
              });
            }
          },
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
    _adminCodeController.dispose();
    super.dispose();
  }
}
