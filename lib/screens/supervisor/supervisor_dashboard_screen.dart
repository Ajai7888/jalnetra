import 'package:flutter/material.dart';

class SupervisorDashboardScreen extends StatelessWidget {
  const SupervisorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('JALNETRA - Supervisor'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'VERIFICATION QUEUE'),
              Tab(text: 'MAP VIEW'),
              Tab(text: 'ALERTS'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildVerificationQueue(),
            const Center(child: Text('Map View Placeholder')),
            const Center(child: Text('Alerts Placeholder')),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationQueue() {
    // This can be a ListView.builder with real data
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildSystemOverview(),
          const SizedBox(height: 20),
          _buildVerificationCard(),
          const SizedBox(height: 20),
          _buildRecentActivity(),
        ],
      ),
    );
  }

  Widget _buildSystemOverview() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "SYSTEM OVERVIEW",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildStatRow("TOTAL SITES", "290"),
            _buildStatRow("ACTIVE", "187 (79%)"),
            _buildStatRow("PENDING VERIFICATION", "12"),
            _buildStatRow("OFFLINE SITES", "5"),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

Widget _buildVerificationCard() {
  return Card(
    clipBehavior: Clip.antiAlias,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Replace the placeholder container with your asset image
        Container(
          height: 180,
          width: double.infinity,
          child: Image.asset(
            'assets/gauge.jpg', // 👈 your image path here
            fit: BoxFit.cover,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Site ID: KL505 (Hooghly River)",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                "Officer: S. Chaterrje",
                style: TextStyle(color: Colors.grey),
              ),
              Text(
                "Timestamp: 2024-10-27 11:45 AM",
                style: TextStyle(color: Colors.grey),
              ),
              Text(
                "Reported Level: 7.3m",
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {},
                      child: const Text("APPROVE"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text("REJECT & NOTIFY"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

  Widget _buildRecentActivity() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "RECENT ACTIVITY",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildActivityItem(
              "Field Officer HRD007 submitted new reading at Ganga River.",
            ),
            _buildActivityItem(
              "Field Officer MHP012 submitted reading at Godavari River.",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(String activity) {
    return ListTile(
      leading: const CircleAvatar(child: Icon(Icons.person)),
      title: Text(activity),
      dense: true,
    );
  }
}
