import 'package:flutter/material.dart';
import 'package:jalnetra01/screens/auth/role_selection_screen.dart';
import 'package:jalnetra01/utils/theme.dart';

void main() {
  runApp(const JalNetraApp());
}

class JalNetraApp extends StatelessWidget {
  const JalNetraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JalNetra',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      home: const RoleSelectionScreen(),
    );
  }
}