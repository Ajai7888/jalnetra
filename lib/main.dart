// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

import 'firebase_options.dart';
import 'package:jalnetra01/utils/theme.dart';
import 'package:jalnetra01/screens/auth/role_selection_screen.dart';

// 🌍 Localization imports
import 'l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Initialize Firebase for all platforms (mobile + web)
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ✅ App Check: enable only on mobile for now (to avoid web crash)
  if (!kIsWeb) {
    await FirebaseAppCheck.instance.activate(
      androidProvider: kDebugMode
          ? AndroidProvider.debug
          : AndroidProvider.playIntegrity,
      // You can add iOS later like:
      // appleProvider: AppleProvider.appAttest,
    );
  }

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

      // 🌍 Localization setup
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
