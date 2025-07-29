import 'package:bus_application/services/excel_export_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  String? selectedFaculty;
  String? selectedBus;

  List<String> facultyList = [];
  List<String> busList = [];

  @override
  void initState() {
    super.initState();
    fetchDropdownOptions();
  }

  Future<void> fetchDropdownOptions() async {
    // 👤 Get distinct scannedBy names
    final logsSnapshot = await FirebaseFirestore.instance
        .collection('attendance_logs')
        .get();

    final faculties = logsSnapshot.docs
        .map((doc) => doc['scannedBy'])
        .where((name) => name != null)
        .toSet()
        .cast<String>()
        .toList();

    final buses = logsSnapshot.docs
        .map((doc) => doc['busNumber'])
        .where((bus) => bus != null)
        .toSet()
        .cast<String>()
        .toList();

    setState(() {
      facultyList = faculties;
      busList = buses;
    });
  }

  Future<void> _exportFilteredLogs() async {
    try {
      if (!(await Permission.storage.request().isGranted)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Storage permission denied')),
        );
        return;
      }

      final filePath = await ExcelExportService.exportLogsToExcel(
        scannedBy: selectedFaculty,
        busNumber: selectedBus,
      );

      if (filePath != null) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('✅ Excel Exported!')));

        Share.shareXFiles([XFile(filePath)], text: '📊 Bus Attendance Report');
      } else {
        throw 'Export failed';
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("📤 Export Attendance Report"),
        backgroundColor: Colors.indigo,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: "Filter by Faculty"),
              value: selectedFaculty,
              items: [
                const DropdownMenuItem(value: null, child: Text("All")),
                ...facultyList.map(
                  (name) => DropdownMenuItem(value: name, child: Text(name)),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  selectedFaculty = value;
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: "Filter by Bus Number",
              ),
              value: selectedBus,
              items: [
                const DropdownMenuItem(value: null, child: Text("All")),
                ...busList.map(
                  (bus) => DropdownMenuItem(value: bus, child: Text(bus)),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  selectedBus = value;
                });
              },
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _exportFilteredLogs,
              icon: const Icon(Icons.download),
              label: const Text("Export Today’s Logs"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
