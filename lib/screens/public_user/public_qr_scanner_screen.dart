// lib/screens/public_user/public_qr_scanner_screen.dart

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../main.dart';
import '../../l10n/app_localizations.dart';

class PublicQRScannerScreen extends StatefulWidget {
  const PublicQRScannerScreen({super.key});

  @override
  State<PublicQRScannerScreen> createState() => _PublicQRScannerScreenState();
}

class _PublicQRScannerScreenState extends State<PublicQRScannerScreen> {
  final MobileScannerController cameraController = MobileScannerController();
  bool _isPermissionGranted = false;
  bool _isCheckingPermission = true;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    setState(() => _isCheckingPermission = true);

    PermissionStatus status = await Permission.camera.status;
    if (!status.isGranted) status = await Permission.camera.request();

    if (!mounted) return;

    setState(() {
      _isPermissionGranted = status.isGranted;
      _isCheckingPermission = false;
    });

    final t = AppLocalizations.of(context)!;

    if (status.isDenied) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.cameraDenied)));
    } else if (status.isPermanentlyDenied) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.cameraPermanentlyDenied)));
    }
  }

  Future<void> _openAppSettings() async {
    await openAppSettings();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    Locale locale = Localizations.localeOf(context);
    String selectedLang = locale.languageCode;
    Map<String, String> langMap = {
      "en": "English",
      "hi": "हिन्दी",
      "ta": "தமிழ்",
    };

    if (_isCheckingPermission) {
      return Scaffold(
        appBar: AppBar(
          title: Text(t.qrScanner),
          actions: [
            DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedLang,
                icon: const Icon(Icons.language, color: Colors.white),
                dropdownColor: Colors.black,
                items: langMap.entries
                    .map(
                      (e) =>
                          DropdownMenuItem(value: e.key, child: Text(e.value)),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) JalNetraApp.setLocale(context, Locale(v));
                },
              ),
            ),
          ],
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (!_isPermissionGranted) {
      return Scaffold(
        appBar: AppBar(
          title: Text(t.qrScanner),
          actions: [
            DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedLang,
                icon: const Icon(Icons.language, color: Colors.white),
                dropdownColor: Colors.black,
                items: langMap.entries
                    .map(
                      (e) =>
                          DropdownMenuItem(value: e.key, child: Text(e.value)),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) JalNetraApp.setLocale(context, Locale(v));
                },
              ),
            ),
          ],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.camera_alt_outlined, size: 60),
                const SizedBox(height: 16),
                Text(t.cameraPermissionRequired, textAlign: TextAlign.center),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _checkPermissions,
                  icon: const Icon(Icons.refresh),
                  label: Text(t.retryPermission),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: _openAppSettings,
                  icon: const Icon(Icons.settings),
                  label: Text(t.openSettings),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(t.scanQrCode),
        backgroundColor: Colors.black,
        actions: [
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedLang,
              icon: const Icon(Icons.language, color: Colors.white),
              dropdownColor: Colors.black,
              items: langMap.entries
                  .map(
                    (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) JalNetraApp.setLocale(context, Locale(v));
              },
            ),
          ),
        ],
      ),
      body: MobileScanner(
        controller: cameraController,
        onDetect: (capture) {
          final barcodes = capture.barcodes;
          if (barcodes.isNotEmpty) {
            final qrValue = barcodes.first.rawValue ?? "";
            if (qrValue.isNotEmpty) {
              cameraController.stop();
              // Pass the result back to the calling screen
              Navigator.pop(context, qrValue);
            }
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }
}
