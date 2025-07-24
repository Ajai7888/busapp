// lib/screens/report_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:bus_application/services/excel_export_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  Future<void> _exportToExcel(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final facultyName = userDoc['name'] ?? 'Unknown';

    final snapshot = await FirebaseFirestore.instance
        .collection('attendance')
        .doc(facultyName)
        .collection('scans')
        .get();

    final records = snapshot.docs.map((doc) => doc.data()).toList();

    final success = await ExcelExportService.exportRawMapList(records);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Excel Exported Successfully!' : 'Export failed',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Export Attendance Report")),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _exportToExcel(context),
          child: const Text("Export as Excel"),
        ),
      ),
    );
  }
}
