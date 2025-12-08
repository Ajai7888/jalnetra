// lib/screens/field_officer/capture_flow_screen.dart

import 'dart:io';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart'; // Still needed for XFile type
import 'package:steganograph/steganograph.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:jalnetra01/common/custom_button.dart';
import 'package:jalnetra01/common/firebase_service.dart';
import 'package:jalnetra01/models/reading_model.dart';
import 'package:jalnetra01/main.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../../l10n/app_localizations.dart';
import 'live_gauge_validation_screen.dart';
import 'qr_scanner_screen.dart';
import 'package:camera/camera.dart';

// DATA MODELS (Required for Capture Flow)
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

class SiteMetrics {
  final String name;
  final double fullTankLevelMeters;
  final double fullCapacityTMC;

  SiteMetrics({
    required this.name,
    required this.fullTankLevelMeters,
    required this.fullCapacityTMC,
  });
}

class CaptureFlowScreen extends StatefulWidget {
  const CaptureFlowScreen({super.key});

  @override
  State<CaptureFlowScreen> createState() => _CaptureFlowScreenState();
}

class _CaptureFlowScreenState extends State<CaptureFlowScreen> {
  int _currentStep = 1;
  final _formKey = GlobalKey<FormState>();

  final _levelController = TextEditingController();
  final _autoLevelController = TextEditingController();

  final FirebaseService _firebaseService = FirebaseService();

  File? _capturedImage;
  QRSiteData? _scannedQRData;
  SiteMetrics? _siteMetrics;
  bool _isWithinGeofence = false;
  bool _isCheckingStatus = false;
  bool _hasValidatedGeofence = false;
  double _distanceFromSite = 0.0;
  Position? _currentPosition;
  bool _isSubmitting = false;

  bool _isDLProcessing = false;

  /// NEW: DL result status (for “not gauge” message)
  bool _isGaugeImage = true;
  String? _gaugeValidationMessage;

  static const String _dlApiUrl =
      'https://ericjeevan-gaugeapidoc.hf.space/predict';

  static const double geofenceLimitMeters = 25.0;

  final stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;
  String _recognizedText = '';

  List<CameraDescription> _cameras = [];

  // ⚠️ NEW METHOD: Initialize cameras list
  Future<void> _initializeCameras() async {
    try {
      _cameras = await availableCameras();
    } catch (e) {
      debugPrint("Error initializing available cameras: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    _initSpeech();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLiveLocation();
      _initializeCameras(); // Initialize cameras early
    });
  }

  @override
  void dispose() {
    _levelController.dispose();
    _autoLevelController.dispose();
    _speechToText.cancel();
    super.dispose();
  }

  // --- Speech-to-Text Logic (UNCHANGED) ---
  Future<bool> _isSecureEnvironmentForLocation() async {
    return true;
  }

  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize(
      onError: (e) => debugPrint('STT Error: ${e.errorMsg}'),
    );
    if (mounted) setState(() {});
  }

  void _toggleListening() async {
    final t = AppLocalizations.of(context)!;

    if (!_speechEnabled) {
      _showSnackBar(t.speechNotAvailable, Colors.red);
      return;
    }

    if (_isListening) {
      await _speechToText.stop();
      if (mounted) setState(() => _isListening = false);
      _processSpeechResult();
    } else {
      _recognizedText = '';
      FocusScope.of(context).unfocus();

      await _speechToText.listen(
        onResult: _onSpeechResult,
        localeId: 'en_US',
        listenFor: const Duration(seconds: 10),
      );

      if (mounted) {
        setState(() => _isListening = _speechToText.isListening);
      }
    }
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    if (!mounted) return;

    setState(() {
      _recognizedText = result.recognizedWords;

      if (result.finalResult) {
        _isListening = false;
        _processSpeechResult();
      }
    });
  }

  void _processSpeechResult() {
    final t = AppLocalizations.of(context)!;

    if (_recognizedText.isEmpty) return;

    final cleanText = _recognizedText.replaceAll(RegExp(r'[^\d\.]'), '');
    final parsedLevel = double.tryParse(cleanText);

    if (parsedLevel != null && parsedLevel >= 0 && parsedLevel < 100) {
      _levelController.text = parsedLevel.toStringAsFixed(2);
      _showSnackBar(
        '${t.voiceLevelDetected} ${parsedLevel.toStringAsFixed(2)}m',
        Colors.green,
      );
    } else {
      _showSnackBar(t.voiceInvalidInput, Colors.orange);
      _levelController.clear();
    }

    _recognizedText = '';
  }

  // --- Geolocation and Geofence Logic (UNCHANGED) ---

  Future<void> _checkLiveLocation() async {
    final t = AppLocalizations.of(context)!;

    setState(() {
      _isCheckingStatus = true;
      _currentPosition = null;
      _currentStep = 1;
    });

    try {
      final safe = await _isSecureEnvironmentForLocation();
      if (!safe) return;

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions denied.');
      }

      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
        timeLimit: const Duration(seconds: 15),
      );

      if (mounted) {
        setState(() => _currentStep = 2);
      }
    } catch (e) {
      debugPrint('GPS Error in CaptureFlow: $e');
      _showSnackBar(t.gpsError, Colors.red);
      if (mounted) setState(() => _currentStep = 1);
    } finally {
      if (mounted) {
        setState(() => _isCheckingStatus = false);
      }
    }
  }

  Future<void> _scanAndParseQR() async {
    final t = AppLocalizations.of(context)!;

    setState(() {
      _isCheckingStatus = true;
      _hasValidatedGeofence = false;
      _siteMetrics = null;
    });

    final result = await Navigator.push<String?>(
      context,
      MaterialPageRoute(builder: (_) => const QRScannerScreen()),
    );

    if (result == null || result.isEmpty) {
      _showSnackBar(t.qrCancelled, Colors.orange);
      if (mounted) setState(() => _currentStep = 1);
      return;
    }

    try {
      final siteIdMatch = RegExp(r'SITE ID: ([A-Z0-9-]+)').firstMatch(result);
      final latMatch = RegExp(r'LATITUDE: ([\d\.]+)').firstMatch(result);
      final lonMatch = RegExp(r'LONGITUDE: ([\d\.]+)').firstMatch(result);
      final nameMatch = RegExp(r'NAME: ([A-Z ]+)').firstMatch(result);
      final levelMatch = RegExp(
        r'FULL TANK LEVEL \(m\): ([\d\.]+)',
      ).firstMatch(result);
      final capacityMatch = RegExp(
        r'FULL CAPACITY \(TMC\): ([\d\.]+)',
      ).firstMatch(result);

      if (siteIdMatch == null ||
          latMatch == null ||
          lonMatch == null ||
          nameMatch == null ||
          levelMatch == null ||
          capacityMatch == null) {
        throw Exception('Missing QR fields');
      }

      final siteId = siteIdMatch.group(1)!;
      final fixedLat = double.parse(latMatch.group(1)!);
      final fixedLon = double.parse(lonMatch.group(1)!);
      final siteName = nameMatch.group(1)!.trim();
      final fullLevel = double.parse(levelMatch.group(1)!);
      final fullCapacity = double.parse(capacityMatch.group(1)!);

      _scannedQRData = QRSiteData(
        siteId: siteId,
        latitude: fixedLat,
        longitude: fixedLon,
        timestamp: DateTime.now(),
      );

      _siteMetrics = SiteMetrics(
        name: siteName,
        fullTankLevelMeters: fullLevel,
        fullCapacityTMC: fullCapacity,
      );

      if (mounted) {
        setState(() => _currentStep = 3);
      }
    } catch (e) {
      _showSnackBar('${t.qrProcessingFailed} $e', Colors.red);
      if (mounted) setState(() => _currentStep = 2);
    } finally {
      if (mounted) {
        setState(() => _isCheckingStatus = false);
      }
    }
  }

  Future<void> _validateGeofence() async {
    if (_currentPosition == null || _scannedQRData == null) {
      if (mounted) setState(() => _currentStep = 1);
      return;
    }

    setState(() {
      _isCheckingStatus = true;
      _isWithinGeofence = false;
      _distanceFromSite = 0.0;
    });

    final distance = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      _scannedQRData!.latitude,
      _scannedQRData!.longitude,
    );

    if (mounted) {
      setState(() {
        _distanceFromSite = distance;
        _isWithinGeofence = distance <= geofenceLimitMeters;
        _isCheckingStatus = false;
      });
    }
  }

  // 🚀 STEP 4: Capture Photo (Launches Live Validation)
  Future<void> _capturePhoto() async {
    final t = AppLocalizations.of(context)!;

    if (_cameras.isEmpty) {
      _showSnackBar(
        "Camera not available. Retrying initialization...",
        Colors.red,
      );
      await _initializeCameras(); // Attempt to initialize cameras again
      if (_cameras.isEmpty) {
        if (mounted) setState(() => _currentStep = 3);
        return;
      }
    }

    // Navigate to the live validation screen
    final XFile? pickedFile = await Navigator.push<XFile?>(
      context,
      MaterialPageRoute(
        builder: (_) => LiveCameraValidationScreen(cameras: _cameras),
      ),
    );

    if (pickedFile != null) {
      setState(() {
        _capturedImage = File(pickedFile.path);
        _currentStep = 5;
        _autoLevelController.clear();
        _isGaugeImage = true;
        _gaugeValidationMessage = null;
      });
      // 🎯 DL API call (Step 5 logic) for data extraction
      _processImageWithDLModel(_capturedImage!);
    } else {
      // If the user presses the back button on the validation screen, it returns null.
      _showSnackBar(t.photoCancelled, Colors.orange);
      if (mounted) setState(() => _currentStep = 3);
    }
  }

  // 🎯 DL API call (Step 5 logic) for data extraction
  Future<void> _processImageWithDLModel(File imageFile) async {
    final t = AppLocalizations.of(context)!;

    _autoLevelController.clear();
    _isGaugeImage = true;
    _gaugeValidationMessage = null;

    setState(() => _isDLProcessing = true);

    try {
      final uri = Uri.parse(_dlApiUrl);

      final request = http.MultipartRequest('POST', uri)
        ..files.add(
          await http.MultipartFile.fromPath(
            'file', // backend expects "file"
            imageFile.path,
            contentType: MediaType('image', 'jpeg'),
          ),
        );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('DL API raw response (field officer): ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        String? message;
        String? error;

        if (jsonResponse is Map<String, dynamic>) {
          message = jsonResponse['message']?.toString();
          error = jsonResponse['error']?.toString();
        }

        // 🔴 Case 1: API sent an error (e.g. "Ruler not detected" / "Could not parse image result")
        if (error != null && error.isNotEmpty) {
          debugPrint('DL API error: $error');

          // Mark as NOT a gauge image
          setState(() {
            _isGaugeImage = false;
            _gaugeValidationMessage =
                'No gauge detected in this image. Please recapture the water-level gauge.';
          });

          _showSnackBar('${t.dlFailed}: No gauge detected.', Colors.orange);
          return;
        }

        // 🔵 Case 2: normal success – parse water level from "message"
        if (message == null || message.isEmpty) {
          debugPrint('DL API: message field missing');

          setState(() {
            _isGaugeImage = false;
            _gaugeValidationMessage =
                'No gauge detected in this image. Please recapture the water-level gauge.';
          });

          _showSnackBar('${t.dlFailed}: No gauge detected.', Colors.orange);
          return;
        }

        // Extract first number like 4.0 from the message
        final match = RegExp(r'([0-9]+(?:\.[0-9]+)?)').firstMatch(message);
        final levelString = match?.group(1); // e.g. "4.0"
        final parsedLevel = double.tryParse(levelString ?? '');

        if (parsedLevel != null) {
          if (mounted) {
            setState(() {
              final value = parsedLevel.toStringAsFixed(2);
              _autoLevelController.text = value; // auto value only
              _isGaugeImage = true;
              _gaugeValidationMessage = null;
            });
          }
          _showSnackBar(t.dlSuccess, Colors.blue);
        } else {
          // No usable number even though "message" exists -> treat as not gauge
          debugPrint('DL API: could not parse number from message: $message');
          setState(() {
            _isGaugeImage = false;
            _gaugeValidationMessage =
                'No gauge detected in this image. Please recapture the water-level gauge.';
          });
          _showSnackBar('${t.dlFailed}: No gauge detected.', Colors.orange);
        }
      } else {
        _showSnackBar('${t.dlApiError} ${response.statusCode}', Colors.red);
        debugPrint('DL API Error status: ${response.statusCode}');
        debugPrint('DL API Error body: ${response.body}');
      }
    } catch (e) {
      _showSnackBar(t.dlProcessingError, Colors.red);
      debugPrint('DL Processing Exception: $e');
    } finally {
      if (mounted) {
        setState(() => _isDLProcessing = false);
      }
    }
  }

  Future<File> _encodeReadingData(File originalImage, double waterLevel) async {
    final user = FirebaseAuth.instance.currentUser!;
    final officerEmail = user.email ?? 'N/A';

    final autoLevel = _autoLevelController.text;

    final metadata =
        'SiteID:${_scannedQRData!.siteId}|'
        'SiteName:${_siteMetrics?.name ?? 'N/A'}|'
        'OfficerID:${user.uid}|'
        'OfficerEmail:$officerEmail|'
        'LevelManual:${waterLevel.toStringAsFixed(2)}m|'
        'LevelAuto:$autoLevel m|'
        'TankLevelMax:${_siteMetrics?.fullTankLevelMeters.toStringAsFixed(2) ?? 'N/A'}m|'
        'CapacityMax:${_siteMetrics?.fullCapacityTMC.toStringAsFixed(2) ?? 'N/A'}TMC|'
        'GeoLiveLat:${_currentPosition!.latitude.toStringAsFixed(5)}|'
        'GeoLiveLon:${_currentPosition!.longitude.toStringAsFixed(5)}|'
        'GeoQRLat:${_scannedQRData!.latitude.toStringAsFixed(5)}|'
        'GeoQRLon:${_scannedQRData!.longitude.toStringAsFixed(5)}|'
        'Timestamp:${DateTime.now().toUtc().toIso8601String()}';

    final originalBytes = await originalImage.readAsBytes();
    final encodedBytes = await Steganograph.cloakBytes(
      imageBytes: originalBytes,
      message: metadata,
      outputFilePath: originalImage.path,
    );

    if (encodedBytes == null) {
      throw Exception('Failed to embed Steganography data.');
    }

    await originalImage.writeAsBytes(encodedBytes);
    return originalImage;
  }

  Future<void> _submitReading(bool isManual) async {
    final t = AppLocalizations.of(context)!;

    if (!_formKey.currentState!.validate() || _capturedImage == null) {
      _showSnackBar(t.missingData, Colors.red);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final waterLevel = double.parse(_levelController.text);
      final encodedImageFile = await _encodeReadingData(
        _capturedImage!,
        waterLevel,
      );

      final user = FirebaseAuth.instance.currentUser!;
      final reading = WaterReading(
        id: '',
        siteId: _scannedQRData!.siteId,
        officerId: user.uid,
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

      if (mounted) {
        _showSnackBar(t.readingSubmitted, Colors.green);
        Navigator.pop(context);
      }
    } catch (e) {
      _showSnackBar('${t.submissionFailed} $e', Colors.red);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  // --- UI Builder Methods ---

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 1:
        return _buildStep1LiveLocation();
      case 2:
        return _buildStep2QRScan();
      case 3:
        return _buildStep3GeofenceValidation();
      case 4:
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _capturePhoto();
        });
        return _buildCameraLaunchingUI();
      case 5:
        return _buildStep5LogReading();
      default:
        return const Center(child: Text('Flow Error: Restarting.'));
    }
  }

  Widget _buildCameraLaunchingUI() {
    final t = AppLocalizations.of(context)!;

    // This screen is now just a placeholder before navigating to the live view
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text("${t.prepareCamera}\n(Starting Live Validation...)"),
        ],
      ),
    );
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
        title: Text('${t.step} $_currentStep/5: ${t.captureReading}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_currentStep > 1) {
              setState(() => _currentStep--);
              if (_currentStep == 3) _hasValidatedGeofence = false;
            } else {
              Navigator.pop(context);
            }
          },
        ),
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _buildStepContent(),
      ),
    );
  }

  Widget _buildStep1LiveLocation() {
    final t = AppLocalizations.of(context)!;

    return Column(
      children: [
        Text(
          '${t.step} 1/5: ${t.getLiveLocation}',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                ? '${t.gpsFound}: '
                      '${_currentPosition!.latitude.toStringAsFixed(4)}, '
                      '${_currentPosition!.longitude.toStringAsFixed(4)}'
                : t.awaitingGps,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const Spacer(),
        CustomButton(
          text: _currentPosition != null ? t.proceedToQrScan : t.retryGps,
          icon: Icons.qr_code_scanner,
          color: _currentPosition != null
              ? Theme.of(context).primaryColor
              : Colors.grey,
          onPressed: _currentPosition != null
              ? () => setState(() => _currentStep = 2)
              : () => _checkLiveLocation(),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildStep2QRScan() {
    final t = AppLocalizations.of(context)!;

    return Column(
      children: [
        Text(
          '${t.step} 2/5: ${t.scanQrCode}',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 30),
        Icon(Icons.qr_code_2, size: 150, color: Theme.of(context).primaryColor),
        const SizedBox(height: 30),
        Text(
          t.scanInstruction,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, color: Colors.white70),
        ),
        const SizedBox(height: 8),
        const Text(
          'This retrieves the official site ID and Geo-reference.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
        const Spacer(),
        CustomButton(
          text: t.startQrScanner,
          icon: Icons.scanner,
          color: Colors.blueAccent,
          onPressed: () {
            if (!_isCheckingStatus) {
              _scanAndParseQR();
            }
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildStep3GeofenceValidation() {
    final t = AppLocalizations.of(context)!;

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
      statusText = t.validatingPosition;
      statusColor = Colors.orange;
      statusIcon = Icons.sync;
    } else if (_isWithinGeofence) {
      statusText = t.geofencePassed;
      statusColor = Theme.of(context).primaryColor;
      statusIcon = Icons.check_circle;
    } else {
      statusText = t.geofenceFailed;
      statusColor = Colors.red;
      statusIcon = Icons.error;
    }

    return Column(
      children: [
        Text(
          '${t.step} 3/5: Geofence',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Site ID: ${_scannedQRData?.siteId ?? 'N/A'}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('Site Name: ${_siteMetrics?.name ?? 'N/A'}'),
                const Divider(),
                Text(
                  'Max Level: ${_siteMetrics?.fullTankLevelMeters.toStringAsFixed(2) ?? 'N/A'} meters',
                ),
                Text(
                  'Max Capacity: ${_siteMetrics?.fullCapacityTMC.toStringAsFixed(2) ?? 'N/A'} TMC',
                ),
                const Divider(),
                Text(
                  'QR Geo-Ref: '
                  'Lat ${_scannedQRData?.latitude.toStringAsFixed(4) ?? 'N/A'}, '
                  'Lon ${_scannedQRData?.longitude.toStringAsFixed(4) ?? 'N/A'}',
                ),
                Text(
                  'Live GPS: '
                  'Lat ${_currentPosition?.latitude.toStringAsFixed(4) ?? 'N/A'}, '
                  'Lon ${_currentPosition?.longitude.toStringAsFixed(4) ?? 'N/A'}',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
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
                  '${t.distanceToSite}: ${_distanceFromSite.toStringAsFixed(1)} m',
                  style: TextStyle(fontSize: 20, color: statusColor),
                ),
                const SizedBox(height: 4),
                const Text(
                  '(Required: Max 25.0 m)',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
        CustomButton(
          text: _isWithinGeofence ? t.proceedToCapture : t.backAndRetry,
          icon: _isWithinGeofence ? Icons.camera : Icons.arrow_back,
          color: _isWithinGeofence
              ? Theme.of(context).primaryColor
              : Colors.red,
          onPressed: _isWithinGeofence
              ? () => setState(() => _currentStep = 4)
              : () {
                  setState(() {
                    _currentStep = 1;
                    _hasValidatedGeofence = false;
                  });
                  _checkLiveLocation();
                },
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildStep5LogReading() {
    final t = AppLocalizations.of(context)!;
    final siteMetrics = _siteMetrics;

    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            Text(
              '${t.step} 5/5: ${t.logReading}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 20),
            if (siteMetrics != null)
              Card(
                color: Theme.of(context).cardColor.withOpacity(0.8),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Site: ${siteMetrics.name} (${_scannedQRData?.siteId})',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Max Level: ${siteMetrics.fullTankLevelMeters.toStringAsFixed(2)} m',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      Text(
                        'Max Capacity: ${siteMetrics.fullCapacityTMC.toStringAsFixed(2)} TMC',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
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
                  : Center(
                      child: Text(
                        t.imagePreview,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
            ),

            /// 🔴 NEW: Big warning when the image is not a gauge
            if (!_isGaugeImage && _gaugeValidationMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.redAccent),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.redAccent,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _gaugeValidationMessage!,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Automatic DL Entry Box
            TextFormField(
              controller: _autoLevelController,
              readOnly: true,
              decoration: InputDecoration(
                labelText: t.autoWaterLevel,
                suffixText: 'm',
                prefixIcon: _isDLProcessing
                    ? const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : const Icon(Icons.memory),
                hintText: _isDLProcessing ? t.processingImage : t.awaitingDl,
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 20),

            // Manual entry
            TextFormField(
              controller: _levelController,
              decoration: InputDecoration(
                labelText: t.manualWaterLevel,
                suffixText: 'm',
                prefixIcon: const Icon(Icons.edit_note),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isListening ? Icons.mic : Icons.mic_none,
                    color: _isListening ? Colors.redAccent : Colors.white70,
                  ),
                  onPressed: _speechEnabled ? () => _toggleListening() : null,
                  tooltip: _isListening ? 'Tap to Stop' : 'Tap for Voice Input',
                ),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (value) =>
                  (value == null || value.isEmpty) ? t.levelRequired : null,
            ),

            if (_isListening)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  '${t.speechRecognizing}: $_recognizedText',
                  style: const TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.blueAccent,
                  ),
                ),
              ),
            const SizedBox(height: 30),
            _isSubmitting
                ? const Center(child: CircularProgressIndicator())
                : CustomButton(
                    text: t.submitAndEncrypt,
                    icon: Icons.lock,
                    color: Colors.blue,
                    onPressed: () => _submitReading(true),
                  ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
