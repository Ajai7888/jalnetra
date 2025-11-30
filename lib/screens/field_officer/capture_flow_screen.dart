// lib/screens/field_officer/capture_flow_screen.dart

import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:steganograph/steganograph.dart';

import 'package:jalnetra01/common/custom_button.dart';
import 'package:jalnetra01/common/firebase_service.dart';
import 'package:jalnetra01/models/reading_model.dart';
import 'package:jalnetra01/utils/constants.dart';
import 'qr_scanner_screen.dart';

// --- DATA MODEL FOR QR CODE ---
class QRSiteData {
  final String siteId;
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  QRSiteData({
    required this.siteId,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });
}

class CaptureFlowScreen extends StatefulWidget {
  const CaptureFlowScreen({super.key});

  @override
  _CaptureFlowScreenState createState() => _CaptureFlowScreenState();
}

class _CaptureFlowScreenState extends State<CaptureFlowScreen> {
  // Flow steps: 1: GPS, 2: QR Scan, 3: Geofence, 4: Capture, 5: Log/Submit
  int _currentStep = 1;

  final _formKey = GlobalKey<FormState>();
  final _levelController = TextEditingController();
  final FirebaseService _firebaseService = FirebaseService();

  File? _capturedImage;

  // Geofence & QR State
  QRSiteData? _scannedQRData;
  bool _isWithinGeofence = false;
  bool _isCheckingStatus = true;
  bool _hasValidatedGeofence = false; // <--- NEW FLAG
  double _distanceFromSite = 0.0;
  Position? _currentPosition;

  bool _isSubmitting = false;

  static const double geofenceLimitMeters = 25.0; // 25 meters maximum

  @override
  void initState() {
    super.initState();
    _checkLiveLocation(); // Start the flow automatically
  }

  // --- STEP 1: LIVE LOCATION CHECK ---
  Future<void> _checkLiveLocation() async {
    setState(() {
      _isCheckingStatus = true;
      _currentPosition = null;
      _currentStep = 1;
    });

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          throw Exception("Location permissions denied.");
        }
      }

      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Success -> Move to QR Scan (Step 2)
      if (mounted) setState(() => _currentStep = 2);
    } catch (e) {
      debugPrint('Location Check Error: $e');
      _currentPosition = null;
      _showSnackBar("Location check failed. Enable GPS and retry.", Colors.red);
    } finally {
      if (mounted) setState(() => _isCheckingStatus = false);
    }
  }

  // --- STEP 2: QR SCAN EXECUTION & DATA PARSING ---
  Future<void> _scanAndParseQR() async {
    setState(() {
      _isCheckingStatus = true;
      _hasValidatedGeofence = false; // reset for fresh validation
    });

    // Launch QR Scanner Page
    final String? result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const QRScannerScreen()),
    );

    if (result == null || result.isEmpty) {
      _showSnackBar(
        "QR scanning cancelled or failed. Returning to GPS check.",
        Colors.orange,
      );
      if (mounted) setState(() => _currentStep = 1);
      return;
    }

    try {
      if (_currentPosition == null) {
        throw Exception("Live GPS missing for QR processing.");
      }

      // NOTE: For demo we use live GPS as QR geo-ref.
      // In production, these should come from QR/site master data.
      final qrData = QRSiteData(
        siteId: result,
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        timestamp: DateTime.now(),
      );

      if (mounted) {
        setState(() {
          _scannedQRData = qrData;
          _currentStep = 3; // Move to Geofencing Validation
        });
      }
    } catch (e) {
      _showSnackBar("QR processing failed: $e", Colors.red);
      if (mounted) setState(() => _currentStep = 2);
    } finally {
      if (mounted) setState(() => _isCheckingStatus = false);
    }
  }

  // --- STEP 3: GEOFENCING VALIDATION ---
  Future<void> _validateGeofence() async {
    if (_currentPosition == null || _scannedQRData == null) {
      if (mounted) setState(() => _currentStep = 1);
      return;
    }

    setState(() {
      _isCheckingStatus = true;
      _isWithinGeofence = false;
    });

    // Calculate distance between LIVE GPS and QR's site location
    final distanceInMeters = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      _scannedQRData!.latitude,
      _scannedQRData!.longitude,
    );

    if (mounted) {
      setState(() {
        _distanceFromSite = distanceInMeters;
        _isWithinGeofence = distanceInMeters <= geofenceLimitMeters;
        _isCheckingStatus = false;
      });
    }
  }

  // --- STEP 4: IMAGE CAPTURE (Execution) ---
  Future<void> _capturePhoto() async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 50,
    );

    if (pickedFile != null) {
      setState(() {
        _capturedImage = File(pickedFile.path);
        _currentStep = 5; // Move to Log Reading step
      });
    } else {
      _showSnackBar("Photo capture cancelled. Please retry.", Colors.orange);
      if (mounted) {
        setState(() => _currentStep = 3); // Go back to geofencing step
      }
    }
  }

  // lib/screens/field_officer/capture_flow_screen.dart

  // ... (existing code and imports) ...

  // --- STEP 5: LOG READING & SUBMISSION (Steganography) ---
  Future<File> _encodeReadingData(File originalImage, double waterLevel) async {
    final user = FirebaseAuth.instance.currentUser;
    final officerEmail = user!.email ?? 'N/A'; // Get email for audit trail

    String metadata =
        // ----------------------------------------------------------------------------------
        // FINAL AUDIT METADATA STRUCTURE
        // ----------------------------------------------------------------------------------
        "SiteID:${_scannedQRData!.siteId}|"
        "OfficerID:${user.uid}|"
        "OfficerEmail:$officerEmail|" // INCLUDE OFFICER EMAIL
        "Level:${waterLevel.toStringAsFixed(2)}m|"
        "GeoLiveLat:${_currentPosition!.latitude.toStringAsFixed(5)}|"
        "GeoLiveLon:${_currentPosition!.longitude.toStringAsFixed(5)}|"
        "GeoQRLat:${_scannedQRData!.latitude.toStringAsFixed(5)}|"
        "GeoQRLon:${_scannedQRData!.longitude.toStringAsFixed(5)}|"
        "Timestamp:${DateTime.now().toUtc().toIso8601String()}";

    final originalBytes = await originalImage.readAsBytes();
    final encodedBytes = await Steganograph.cloakBytes(
      imageBytes: originalBytes,
      message: metadata,
      outputFilePath: originalImage.path,
    );

    if (encodedBytes == null) {
      throw Exception("Failed to embed Steganography data.");
    }

    await originalImage.writeAsBytes(encodedBytes);
    return originalImage;
  }

  Future<void> _submitReading(bool isManual) async {
    if (!_formKey.currentState!.validate() || _capturedImage == null) {
      _showSnackBar("Missing data.", Colors.red);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final double waterLevel = double.parse(_levelController.text);
      final encodedImageFile = await _encodeReadingData(
        _capturedImage!,
        waterLevel,
      );

      final user = FirebaseAuth.instance.currentUser;
      final reading = WaterReading(
        id: '',
        siteId: _scannedQRData!.siteId,
        officerId: user!.uid,
        waterLevel: waterLevel,
        imageUrl: '',
        location: GeoPoint(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        ),
        timestamp: DateTime.now(),
        isManual: isManual,
      );

      await _firebaseService.submitReading(reading, encodedImageFile);

      if (context.mounted) {
        _showSnackBar(
          "Reading submitted successfully!",
          Theme.of(context).primaryColor,
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("Submission Error: $e");
      if (context.mounted) {
        _showSnackBar("Submission failed. Error: $e", Colors.red);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // --- UTILITY METHODS ---
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 1:
        return _buildStep1LiveLocation();
      case 2:
        return _buildStep2QRScan();
      case 3:
        return _buildStep3GeofenceValidation();
      case 4:
        // Automatically move to capture camera when in step 4
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _capturePhoto();
        });
        return _buildCameraLaunchingUI();
      case 5:
        return _buildStep5LogReading();
      default:
        return const Center(child: Text("Flow Error: Restarting."));
    }
  }

  Widget _buildCameraLaunchingUI() {
    return Scaffold(
      appBar: AppBar(title: const Text("Launching Camera")),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text("Launching Camera for Gauge Capture..."),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Step $_currentStep/5: Capture Reading'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_currentStep > 1) {
              setState(() {
                _currentStep--;
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _buildStepContent(),
      ),
    );
  }

  // --- STEP 1 UI ---
  Widget _buildStep1LiveLocation() {
    return Column(
      children: [
        const Text(
          "STEP 1/5: Get Live Location",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: Center(
            child: _isCheckingStatus
                ? const CircularProgressIndicator()
                : Icon(
                    _currentPosition != null
                        ? Icons.my_location
                        : Icons.location_off,
                    size: 80,
                    color: _currentPosition != null
                        ? Theme.of(context).primaryColor
                        : Colors.red,
                  ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(50),
          ),
          child: Text(
            _currentPosition != null
                ? "GPS Found: Lat: ${_currentPosition!.latitude.toStringAsFixed(4)} Lng: ${_currentPosition!.longitude.toStringAsFixed(4)}"
                : "Awaiting GPS Fix...",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const Spacer(),
        CustomButton(
          text: _currentPosition != null ? "PROCEED TO QR SCAN" : "RETRY GPS",
          onPressed: _currentPosition != null
              ? () => setState(() => _currentStep = 2)
              : _checkLiveLocation,
          icon: Icons.qr_code_scanner,
          color: _currentPosition != null
              ? Theme.of(context).primaryColor
              : Colors.grey,
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // --- STEP 2 UI ---
  Widget _buildStep2QRScan() {
    return Column(
      children: [
        const Text(
          "STEP 2/5: Scan Site QR Code",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 30),
        Icon(Icons.qr_code_2, size: 150, color: Theme.of(context).primaryColor),
        const SizedBox(height: 30),
        const Text(
          "Scan the physical QR code on the gauge post.",
          style: TextStyle(fontSize: 18, color: Colors.white70),
        ),
        const Text(
          "This retrieves the official site ID and Geo-reference.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
        const Spacer(),
        CustomButton(
          text: "START QR SCANNER",
          onPressed: () {
            if (_isCheckingStatus) return;
            _scanAndParseQR();
          },
          icon: Icons.scanner,
          color: Colors.blueAccent,
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // --- STEP 3 UI ---
  Widget _buildStep3GeofenceValidation() {
    // trigger validation once when we enter this step
    if (!_hasValidatedGeofence) {
      _hasValidatedGeofence = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _validateGeofence();
      });
    }

    String statusText;
    Color statusColor;
    IconData statusIcon;

    if (_isCheckingStatus) {
      statusText = "Validating Position...";
      statusColor = Colors.orange;
      statusIcon = Icons.sync;
    } else if (_isWithinGeofence) {
      statusText = "✓ GEOFENCE PASSED";
      statusColor = Theme.of(context).primaryColor;
      statusIcon = Icons.check_circle;
    } else {
      statusText = "✗ VALIDATION FAILED (Out of Range)";
      statusColor = Colors.red;
      statusIcon = Icons.error;
    }

    return Column(
      children: [
        const Text(
          "STEP 3/5: Geofence Validation",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),

        // QR & GPS details
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Site ID: ${_scannedQRData?.siteId ?? 'N/A'}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const Divider(),
              Text(
                "QR Geo-Ref: Lat ${_scannedQRData?.latitude.toStringAsFixed(4) ?? 'N/A'}, "
                "Lon ${_scannedQRData?.longitude.toStringAsFixed(4) ?? 'N/A'}",
              ),
              Text(
                "Live GPS: Lat ${_currentPosition?.latitude.toStringAsFixed(4) ?? 'N/A'}, "
                "Lon ${_currentPosition?.longitude.toStringAsFixed(4) ?? 'N/A'}",
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Validation Result
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(statusIcon, size: 60, color: statusColor),
                const SizedBox(height: 10),
                Text(
                  statusText,
                  style: TextStyle(fontSize: 18, color: statusColor),
                ),
                const SizedBox(height: 8),
                Text(
                  "Distance to Site: ${_distanceFromSite.toStringAsFixed(1)} meters",
                  style: TextStyle(fontSize: 20, color: statusColor),
                ),
                Text(
                  "(Required: Max $geofenceLimitMeters meters)",
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),

        // Action Button
        CustomButton(
          text: _isWithinGeofence ? "PROCEED TO CAPTURE" : "GO BACK & RETRY",
          onPressed: _isWithinGeofence
              ? () => setState(() => _currentStep = 4)
              : () {
                  setState(() {
                    _currentStep = 1;
                    _hasValidatedGeofence = false;
                  });
                  _checkLiveLocation();
                },
          icon: _isWithinGeofence ? Icons.camera : Icons.arrow_back,
          color: _isWithinGeofence
              ? Theme.of(context).primaryColor
              : Colors.red,
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // --- STEP 5 UI ---
  Widget _buildStep5LogReading() {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            const Text(
              "STEP 5/5: Log Reading (ML/Manual)",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 20),
            Container(
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).primaryColor,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _capturedImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(
                        _capturedImage!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    )
                  : const Center(child: Text("Captured Image Preview")),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _levelController.text = "4.25";
                    },
                    icon: const Icon(
                      Icons.auto_awesome,
                      color: Colors.blueAccent,
                    ),
                    label: const Text("AI Scan (Mock)"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.edit, color: Colors.orange),
                    label: const Text("Manual Entry"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _levelController,
              decoration: const InputDecoration(
                labelText: "Water Level (meters)",
                hintText: "Enter reading manually...",
                suffixText: "m",
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (value) => (value == null || value.isEmpty)
                  ? 'Water level is required'
                  : null,
            ),
            const SizedBox(height: 30),
            _isSubmitting
                ? const Center(child: CircularProgressIndicator())
                : CustomButton(
                    text: "SUBMIT READING & ENCRYPT",
                    icon: Icons.lock,
                    onPressed: () => _submitReading(true),
                    color: Colors.blue,
                  ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _levelController.dispose();
    super.dispose();
  }
}
