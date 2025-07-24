// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Home Dashboard")),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ElevatedButton(
            onPressed: () => context.go('/scan'),
            child: const Text("Scan QR for Attendance"),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () => context.go('/logs'),
            child: const Text("View Attendance Logs"),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () => context.go('/report'),
            child: const Text("Export Report to Excel"),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () => context.go('/profile'),
            child: const Text("My Profile"),
          ),
        ],
      ),
    );
  }
}
