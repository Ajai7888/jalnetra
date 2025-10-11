import 'package:flutter/material.dart';

class CaptureFlowScreen extends StatefulWidget {
  const CaptureFlowScreen({super.key});

  @override
  _CaptureFlowScreenState createState() => _CaptureFlowScreenState();
}

class _CaptureFlowScreenState extends State<CaptureFlowScreen> {
  int _currentStep = 1;

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 1:
        return _buildStep1Geofence();
      case 2:
        return _buildStep2ScanAndCapture();
      case 3:
        return _buildStep3LogReading();
      default:
        return const Center(child: Text("Unknown Step"));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Step $_currentStep/3: Capture Reading'),
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

  // Step 1: Geofence Verification
  Widget _buildStep1Geofence() {
    return Column(
      children: [
        const Text(
          "Thazhambur big lake (TBL001)",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.green, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            // This ClipRRect ensures the image respects the rounded border
            child: ClipRRect(
              borderRadius: BorderRadius.circular(
                11,
              ), // Slightly less than the container's border to avoid aliasing
              child: Image.asset(
                'assets/map_logo.jpg', // The asset image is placed here
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.2),
            borderRadius: BorderRadius.circular(50),
            border: Border.all(color: Colors.green),
          ),
          child: const Text(
            "✓ WITHIN GEOFENCE - 50m",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () => setState(() => _currentStep = 2),
          child: const Text("PROCEED TO SCAN & CAPTURE"),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  // Step 2: Scan QR and Capture Photo
  Widget _buildStep2ScanAndCapture() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          "STEP 2/3: Scan & Capture",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 20),
        Container(
          height: 250,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.green, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(child: Text("Live Camera Feed Placeholder")),
        ),
        const SizedBox(height: 30),
        const ListTile(
          leading: Icon(Icons.qr_code_scanner, size: 40),
          title: Text("1. Scan Site QR Code"),
          subtitle: Text("Point camera at the QR code on the gauge post"),
        ),
        const ListTile(
          leading: Icon(Icons.camera_alt_outlined, size: 40),
          title: Text("2. Capture Live Photo"),
          subtitle: Text("Ensure the gauge markings are clear"),
        ),
        const Spacer(),
        ElevatedButton(
          onPressed: () => setState(() => _currentStep = 3),
          child: const Text("CAPTURE"),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // Step 3: Log the Reading
  Widget _buildStep3LogReading() {
    return Column(
      children: [
        const Text(
          "STEP 3/3: Log Reading",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 20),
        Container(
          height: 250,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.green, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(child: Text("Captured Image Preview")),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.auto_awesome),
                label: const Text("AI Scan"),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.edit),
                label: const Text("Manual Entry"),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        TextFormField(
          decoration: const InputDecoration(
            labelText: "Water Level (meters)",
            hintText: "Enter reading manually...",
          ),
          keyboardType: TextInputType.number,
        ),
        const Spacer(),
        ElevatedButton.icon(
          icon: const Icon(Icons.memory),
          label: const Text("SCAN IMAGE"),
          onPressed: () {},
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
          onPressed: () => Navigator.pop(context), // Finish flow
          child: const Text("SUBMIT READING & ENCRYPT"),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
