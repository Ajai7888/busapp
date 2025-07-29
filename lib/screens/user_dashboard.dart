import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // ✅ Riverpod import
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart'; // ✅ Includes AppAuthProvider + authProvider
import 'bus_selection_screen.dart';
import 'scan_screen.dart';
import 'report_screen.dart';
import 'profile.dart';
import 'attendance_log_screen.dart';

class UserDashboard extends ConsumerWidget {
  const UserDashboard({super.key});

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      context.go('/login'); // ✅ Use GoRouter to redirect
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user; // ✅ Get user from provider

    return Scaffold(
      appBar: AppBar(
        title: const Text("Home Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Logout",
            onPressed: () => _logout(context),
          ),
        ],
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFFF5F6FA),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _dashboardButton(
              label: "Scan QR for Attendance",
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ScanScreen()),
              ),
            ),
            _dashboardButton(
              label: "View Attendance Logs",
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AttendanceLogScreen()),
              ),
            ),
            _dashboardButton(
              label: "My Profile",
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              ),
            ),
            _dashboardButton(
              label: "Select Bus Number",
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => BusSelectionScreen()),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Logged in as: ${user?.role.toUpperCase() ?? ''}",
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dashboardButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: SizedBox(
        width: 280,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.indigo,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(label, style: const TextStyle(fontSize: 16)),
        ),
      ),
    );
  }
}
