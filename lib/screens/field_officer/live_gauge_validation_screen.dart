// lib/screens/field_officer/live_camera_validation_screen.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter_tts/flutter_tts.dart';

// 👇 your existing localization import (same as in capture_flow_screen.dart)
import '../../l10n/app_localizations.dart';

const double MAX_DISTANCE_METERS = 10.0; // distance threshold for "too far"
const String _dlApiUrl =
    'https://ericjeevan-gaugeapidoc.hf.space/predict'; // same as capture_flow

class LiveCameraValidationScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const LiveCameraValidationScreen({super.key, required this.cameras});

  @override
  State<LiveCameraValidationScreen> createState() =>
      _LiveCameraValidationScreenState();
}

class _LiveCameraValidationScreenState
    extends State<LiveCameraValidationScreen> {
  CameraController? _controller;
  bool _isCameraReady = false;

  // Validation state
  bool _isGaugeDetected = false;
  bool _isWithinRange = false;
  String _bottomValidationMessage = "";
  String _centerOverlayMessage = "";

  // Timer for periodic check
  Timer? _apiCheckTimer;
  bool _isCheckingFrame = false;

  // 🔊 Text-to-Speech
  final FlutterTts _flutterTts = FlutterTts();
  String? _lastSpokenMessage;
  bool _ttsReady = false;

  @override
  void initState() {
    super.initState();

    // Use a post-frame callback so that Localizations & context are ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initTts();
      _initializeCamera();
    });
  }

  @override
  void dispose() {
    _apiCheckTimer?.cancel();
    _controller?.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  // 🔊 Decide TTS language based on current app language
  String _getTtsLanguageCode() {
    final langCode = Localizations.localeOf(context).languageCode;
    switch (langCode) {
      case 'ta':
        return 'ta-IN';
      case 'hi':
        return 'hi-IN';
      default:
        return 'en-IN';
    }
  }

  // 🔊 Initialize TTS
  Future<void> _initTts() async {
    try {
      await _flutterTts.setLanguage(_getTtsLanguageCode());
      await _flutterTts.setSpeechRate(0.5); // slower, clearer
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setVolume(1.0);

      _ttsReady = true;

      final t = AppLocalizations.of(context)!;
      _speakOnce(t.liveInitVoice); // e.g. "Initializing camera. Please wait."
    } catch (e) {
      debugPrint("TTS init error: $e");
      _ttsReady = false;
    }
  }

  // 🔊 Speak only when message changes (avoid spam every 2 sec)
  Future<void> _speakOnce(String message) async {
    if (!_ttsReady) return;
    if (_lastSpokenMessage == message) return;

    _lastSpokenMessage = message;
    try {
      await _flutterTts.stop();
      await _flutterTts.speak(message);
    } catch (e) {
      debugPrint("TTS speak error: $e");
    }
  }

  Future<void> _initializeCamera() async {
    final t = AppLocalizations.of(context)!;

    if (widget.cameras.isEmpty) {
      if (mounted) {
        setState(() => _bottomValidationMessage = t.liveNoCamera);
      }
      _speakOnce(t.liveNoCamera);
      return;
    }

    _controller = CameraController(
      widget.cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => widget.cameras.first,
      ),
      ResolutionPreset.medium,
      enableAudio: false,
    );

    try {
      await _controller!.initialize();
      _isCameraReady = true;

      if (mounted) {
        setState(() {
          _bottomValidationMessage = t.liveAimAtGauge; // "Aim at the gauge..."
          _centerOverlayMessage = t.liveChecking; // "Checking..."
        });
      }

      // 🔊 Tell user what to do (in selected language)
      _speakOnce(t.liveCameraReadyVoice);

      _startApiCheckTimer();
    } catch (e) {
      if (mounted) {
        setState(() {
          _bottomValidationMessage = t.liveCameraError;
          _isCameraReady = false;
        });
      }
      _speakOnce(t.liveCameraError);
    }
  }

  void _startApiCheckTimer() {
    // Check every 2 seconds
    _apiCheckTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (!_isCameraReady ||
          _controller == null ||
          !_controller!.value.isInitialized ||
          _controller!.value.isTakingPicture ||
          _isCheckingFrame) {
        return;
      }

      try {
        _isCheckingFrame = true;
        final XFile file = await _controller!.takePicture();
        await _checkGaugeUsingDL(File(file.path));
        // Clean up temporary file
        File(file.path).deleteSync();
      } catch (e) {
        debugPrint('Error capturing frame for validation: $e');
      } finally {
        _isCheckingFrame = false;
      }
    });
  }

  /// Call DL API on current frame and update UI state.
  Future<void> _checkGaugeUsingDL(File imageFile) async {
    if (!mounted) return;
    final t = AppLocalizations.of(context)!;

    setState(() {
      _centerOverlayMessage = t.liveChecking; // "Checking..."
    });

    try {
      final uri = Uri.parse(_dlApiUrl);
      final request = http.MultipartRequest('POST', uri)
        ..files.add(
          await http.MultipartFile.fromPath(
            'file',
            imageFile.path,
            contentType: MediaType('image', 'jpeg'),
          ),
        );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('DL API (live validation) response: ${response.body}');

      if (response.statusCode != 200) {
        // Any non-200 → treat as "not detected"
        if (!mounted) return;
        setState(() {
          _isGaugeDetected = false;
          _isWithinRange = false;
          _centerOverlayMessage = t.liveGaugeNotFound;
          _bottomValidationMessage = t.liveFrameError;
        });

        _speakOnce(t.liveFrameError);
        return;
      }

      final jsonResponse = jsonDecode(response.body);
      String? message;
      String? error;

      if (jsonResponse is Map<String, dynamic>) {
        message = jsonResponse['message']?.toString();
        error = jsonResponse['error']?.toString();
      }

      // 1) Determine if a GAUGE is present at all
      bool gaugeDetected = false;

      if (error != null && error.isNotEmpty) {
        gaugeDetected = false;
      } else if (message != null && message.isNotEmpty) {
        final match = RegExp(r'([0-9]+(?:\.[0-9]+)?)').firstMatch(message);
        gaugeDetected = match != null;
      }

      if (!gaugeDetected) {
        if (!mounted) return;
        setState(() {
          _isGaugeDetected = false;
          _isWithinRange = false;
          _centerOverlayMessage = t.liveGaugeNotFound; // "Gauge Not Found"
          _bottomValidationMessage =
              t.liveGaugeNotDetectedAim; // "Gauge not detected. Aim…"
        });

        // 🔊 Audio: gauge not detected
        _speakOnce(t.liveGaugeNotDetectedAim);
        return;
      }

      // 2) Gauge detected → now work out distance (if your backend sends it)
      double distance = MAX_DISTANCE_METERS;

      if (jsonResponse is Map<String, dynamic>) {
        if (jsonResponse['distance_m'] != null) {
          final maybe = double.tryParse(jsonResponse['distance_m'].toString());
          if (maybe != null) distance = maybe;
        } else {
          distance = 7.5; // fallback – mid value
        }
      }

      if (!mounted) return;

      if (distance <= MAX_DISTANCE_METERS) {
        // Gauge + within range → allow capture
        setState(() {
          _isGaugeDetected = true;
          _isWithinRange = true;
          _centerOverlayMessage = t.liveReadyOverlay;
          _bottomValidationMessage = t.liveReadyBottom;
        });

        // 🔊 Audio: ready to capture
        _speakOnce(t.liveReadyBottom);

        // Stop continuous checks, user can capture
        _apiCheckTimer?.cancel();
      } else {
        // Gauge present but too far
        setState(() {
          _isGaugeDetected = true;
          _isWithinRange = false;
          _centerOverlayMessage = t.liveTooFarOverlay;
          _bottomValidationMessage = t.liveTooFarBottom;
        });

        // 🔊 Audio: move closer
        _speakOnce(t.liveTooFarBottom);
      }
    } catch (e) {
      debugPrint('Live validation DL error: $e');
      if (!mounted) return;
      setState(() {
        _isGaugeDetected = false;
        _isWithinRange = false;
        _centerOverlayMessage = t.liveGaugeNotFound;
        _bottomValidationMessage = t.liveNetworkError;
      });

      // 🔊 Audio: network error
      _speakOnce(t.liveNetworkError);
    }
  }

  Future<void> _captureImageAndReturn() async {
    if (!_isWithinRange ||
        !_isCameraReady ||
        _controller == null ||
        !_controller!.value.isInitialized) {
      return;
    }

    final t = AppLocalizations.of(context)!;

    try {
      _apiCheckTimer?.cancel();
      final XFile file = await _controller!.takePicture();
      _speakOnce(t.liveCaptureSuccess);
      if (mounted) {
        Navigator.pop(context, file);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Capture Error: $e")));
      }
      _speakOnce(t.liveCaptureError);
    }
  }

  // Central Validation Overlay
  Widget _buildValidationOverlay() {
    if (!_isCameraReady) return const SizedBox.shrink();

    Color overlayColor;
    if (_isGaugeDetected && _isWithinRange) {
      overlayColor = Colors.green.withOpacity(0.4); // success
    } else if (_isGaugeDetected && !_isWithinRange) {
      overlayColor = Colors.orange.withOpacity(0.6); // too far
    } else {
      overlayColor = Colors.red.withOpacity(0.7); // no gauge
    }

    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.3,
        decoration: BoxDecoration(
          color: overlayColor,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: _isGaugeDetected && _isWithinRange
                ? Colors.white
                : Colors.yellowAccent,
            width: 3.0,
          ),
        ),
        child: Center(
          child: Text(
            _centerOverlayMessage,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              shadows: [
                Shadow(blurRadius: 5.0, color: Colors.black.withOpacity(0.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    if (!_isCameraReady) {
      // Also localized title
      return Scaffold(
        appBar: AppBar(title: Text(t.liveTitle)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                _bottomValidationMessage.isEmpty
                    ? t.liveInitMessage
                    : _bottomValidationMessage,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // Camera View
          SizedBox(
            height: MediaQuery.of(context).size.height,
            child: CameraPreview(_controller!),
          ),

          // Central Validation Overlay
          _buildValidationOverlay(),

          // Validation Bottom Bar
          Positioned(
            bottom: 120,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _bottomValidationMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Capture Button
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: FloatingActionButton(
                backgroundColor: _isWithinRange
                    ? Colors.green
                    : Colors.grey.shade700,
                onPressed: _isWithinRange ? _captureImageAndReturn : null,
                child: const Icon(Icons.camera_alt, size: 30),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
