// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

import 'firebase_options.dart';
import 'package:jalnetra01/utils/theme.dart';
import 'package:jalnetra01/screens/auth/role_selection_screen.dart';

// 🌍 Localization imports
import 'l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await FirebaseAppCheck.instance.activate(
    androidProvider: kDebugMode
        ? AndroidProvider.debug
        : AndroidProvider.playIntegrity,
  );

  runApp(const JalNetraApp());
}

class JalNetraApp extends StatefulWidget {
  const JalNetraApp({super.key});

  // 🔥 Allow screens to change language dynamically
  static void setLocale(BuildContext context, Locale newLocale) {
    final _JalNetraAppState? state = context
        .findAncestorStateOfType<_JalNetraAppState>();
    state?.updateLocale(newLocale);
  }

  @override
  State<JalNetraApp> createState() => _JalNetraAppState();
}

class _JalNetraAppState extends State<JalNetraApp> {
  Locale _locale = const Locale('en'); // default English

  void updateLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JalNetra',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,

      // 🌍 Here we activate localization
      locale: _locale,
      supportedLocales: const [
        Locale('en'), // English
        Locale('hi'), // Hindi
        Locale('ta'), // Tamil
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate, // from ARB files
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      home: const RoleSelectionScreen(),
    );
  }
}
