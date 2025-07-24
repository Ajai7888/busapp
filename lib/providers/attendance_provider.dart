// lib/providers/attendance_provider.dart
import 'package:flutter/material.dart';
import '../models/attendance_model.dart';
import '../services/firestore_service.dart';

class AttendanceProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  List<AttendanceRecord> _records = [];
  List<AttendanceRecord> get records => _records;

  Future<void> fetchRecords() async {
    _records = await _firestoreService.fetchAttendanceRecords();
    notifyListeners();
  }

  Future<void> addRecord(AttendanceRecord record) async {
    await _firestoreService.addAttendance(record);
    await fetchRecords();
  }

  Future<void> exportToExcel() async {
    // implement this via ExcelExportService when needed
  }
}
