// lib/screens/supervisor/supervisor_alerts_view.dart

import 'package:flutter/material.dart';

class SupervisorAlertsView extends StatelessWidget {
  const SupervisorAlertsView({super.key});

  @override
  Widget build(BuildContext context) {
    // Set a dark background for the whole screen
    return Container(
      color: const Color(0xFF121212), // Very dark background color
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Critical Flood Alert Card (Darker, glowing, red accent)
            _buildCriticalAlertCard(context),

            const SizedBox(height: 20),

            // Section Header
            const Text(
              "Recent Activity & Audits:",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white70, // Slightly desaturated white
              ),
            ),
            const SizedBox(height: 10),

            // 2. List of Alerts (Dark, rounded, glowing list items)
            _buildAlertItem(
              context,
              '⚠️ Validation Failure: Site KL505 (Tamper Check)',
              Colors.yellow.shade700,
            ),
            _buildAlertItem(
              context,
              '💧 Warning Level: Site GHR002 crossed 4.0M',
              Colors.amber,
            ),
            _buildAlertItem(
              context,
              '✅ Reading Verified: Site TBL001 Approved',
              Colors
                  .cyan, // Changed to Cyan for a modern, distinct 'Approved' look
            ),
            _buildAlertItem(
              context,
              '❌ Submission Rejected: Poor Image Quality',
              Colors.red.shade700,
            ),
            _buildAlertItem(
              context,
              '🕒 Site GHR002: Offline for 48 hours',
              Colors.deepOrange.shade400,
            ),
          ],
        ),
      ),
    );
  }

  // --- Widget Builders for Visual Styling ---
  // ... (rest of the code remains the same)
  // ... (rest of the code remains the same)
  // ... (rest of the code remains the same)

  Widget _buildCriticalAlertCard(BuildContext context) {
    // Red background at 40% opacity, Yellow button at 75% opacity
    return Container(
      decoration: BoxDecoration(
        // 1. Red Background: D71921, with 40% opacity (unchanged)
        color: const Color(0xFFD71921).withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            // Matching the glow to the background color
            color: const Color(0xFFD71921).withOpacity(0.3),
            blurRadius: 18.0,
            spreadRadius: 3.0,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "CRITICAL FLOOD ALERT",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            // Decorative line
            Container(height: 2, width: 50, color: Colors.yellowAccent),
            const SizedBox(height: 12),
            const Text(
              "Site TBL001 - Predicted Level 5.5M in 6 Hrs",
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 15),
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("NDMA Notification Sent!"),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              icon: const Icon(Icons.warning, color: Colors.black),
              label: const Text(
                "NOTIFY EMERGENCY SERVICES",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                // 2. Yellow Button: Using yellowAccent with 75% opacity (NEW CHANGE)
                backgroundColor: Colors.yellowAccent.withOpacity(0.75),
                // Foreground color (text) is black for optimal contrast
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  // ... (rest of the code remains the same)

  Widget _buildAlertItem(BuildContext context, String message, Color color) {
    // Darker, rounded ListTile with a slight glow/shadow for emphasis
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(
            0xFF1E1E1E,
          ), // Slightly lighter dark than background
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15), // Color-coded subtle glow
              blurRadius: 8.0,
              spreadRadius: 0.5,
            ),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 4.0,
          ),
          leading: Icon(Icons.circle, color: color, size: 10),
          title: Text(
            message,
            style: const TextStyle(color: Colors.white, fontSize: 15),
          ),
          trailing: const Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: Colors.white54,
          ),
          onTap: () {
            // Placeholder for navigation to detail view
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Viewing detail for: $message")),
            );
          },
        ),
      ),
    );
  }
}
