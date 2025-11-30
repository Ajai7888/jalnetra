// lib/main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:jalnetra01/screens/auth/role_selection_screen.dart';
import 'package:jalnetra01/utils/theme.dart';
import 'package:firebase_app_check/firebase_app_check.dart'; // NEW IMPORT
import 'package:flutter/foundation.dart'; // NEW IMPORT for kDebugMode check

import 'firebase_options.dart';

void main() async {
  // 1. Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 3. Initialize Firebase App Check (Crucial for security)
  await FirebaseAppCheck.instance.activate(
    // Use the Play Integrity provider for Android production builds
    // In development, use AndroidProvider.debug to generate a token for the console.
    androidProvider: kDebugMode
        ? AndroidProvider.debug
        : AndroidProvider.playIntegrity,

    // For iOS, you would use DeviceCheck or App Attest
    // appleProvider: kDebugMode ? AppleProvider.debug : AppleProvider.deviceCheck,
  );

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
