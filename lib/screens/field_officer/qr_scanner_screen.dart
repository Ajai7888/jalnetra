// lib/screens/field_officer/qr_scanner_screen.dart

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController cameraController = MobileScannerController();
  bool _isPermissionGranted = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions(); // Check/request permissions on load
  }

  Future<void> _checkPermissions() async {
    // Request Camera permission at runtime
    final status = await Permission.camera.request();
    if (mounted) {
      setState(() {
        _isPermissionGranted = status.isGranted;
      });
    }
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Camera permission denied. Cannot scan QR.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isPermissionGranted) {
      return Scaffold(
        appBar: AppBar(title: const Text("QR Scanner")),
        body: const Center(
          child: Text(
            "Camera permission needed. Please grant access in settings.",
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan Site QR Code"),
        backgroundColor: Colors.black,
      ),
      body: MobileScanner(
        controller: cameraController,
        // The onDetect callback fires when a QR code is successfully read
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;
          if (barcodes.isNotEmpty) {
            final String qrValue = barcodes.first.rawValue ?? "";
            if (qrValue.isNotEmpty) {
              cameraController.stop();
              // Return the scanned text to the previous screen (CaptureFlowScreen)
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
