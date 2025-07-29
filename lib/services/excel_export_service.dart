import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as excel;
import 'package:path_provider/path_provider.dart';

class ExcelExportService {
  static Future<List<Map<String, dynamic>>> fetchTodayAttendanceLogs({
    String? scannedBy,
    String? busNumber,
  }) async {
    final now = DateTime.now().toLocal();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    Query query = FirebaseFirestore.instance
        .collection('attendance_logs')
        .where(
          'timestamp',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        )
        .where('timestamp', isLessThan: Timestamp.fromDate(endOfDay));

    if (scannedBy != null && scannedBy.isNotEmpty) {
      query = query.where('scannedBy', isEqualTo: scannedBy);
    }

    if (busNumber != null && busNumber.isNotEmpty) {
      query = query.where('busNumber', isEqualTo: busNumber);
    }

    final snapshot = await query.orderBy('timestamp', descending: true).get();

    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>?;

      final timestamp = data?['timestamp'];
      String formattedTimestamp = '';

      if (timestamp is Timestamp) {
        formattedTimestamp = timestamp.toDate().toLocal().toString();
      } else if (timestamp is String) {
        formattedTimestamp = timestamp;
      }

      return {
        'studentId': data?['studentId'] ?? '',
        'busNumber': data?['busNumber'] ?? '',
        'timestamp': formattedTimestamp,
        'scannedBy': data?['scannedBy'] ?? '',
      };
    }).toList();
  }

  static Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      if (await Permission.manageExternalStorage.isGranted) return true;
      final status = await Permission.manageExternalStorage.request();
      return status.isGranted;
    } else {
      final status = await Permission.storage.request();
      return status.isGranted;
    }
  }

  static Future<String?> exportLogsToExcel({
    String? scannedBy,
    String? busNumber,
  }) async {
    final logs = await fetchTodayAttendanceLogs(
      scannedBy: scannedBy,
      busNumber: busNumber,
    );

    if (logs.isEmpty) return null;

    if (!await _requestStoragePermission()) {
      throw Exception("❌ Storage permission denied");
    }

    final workbook = excel.Workbook();
    final sheet = workbook.worksheets[0];

    // Headers
    sheet.getRangeByName('A1').setText('Student ID');
    sheet.getRangeByName('B1').setText('Bus Number');
    sheet.getRangeByName('C1').setText('Timestamp');
    sheet.getRangeByName('D1').setText('Scanned By');

    // Data
    for (int i = 0; i < logs.length; i++) {
      final row = i + 2;
      sheet.getRangeByName('A$row').setText(logs[i]['studentId']);
      sheet.getRangeByName('B$row').setText(logs[i]['busNumber']);
      sheet.getRangeByName('C$row').setText(logs[i]['timestamp']);
      sheet.getRangeByName('D$row').setText(logs[i]['scannedBy']);
    }

    final bytes = workbook.saveAsStream();
    workbook.dispose();

    final directory = await getExternalStorageDirectory();
    if (directory == null) {
      throw Exception("❌ Unable to access external storage directory");
    }

    final filePath = '${directory.path}/attendance_today.xlsx';
    final file = File(filePath);
    await file.writeAsBytes(bytes, flush: true);

    return filePath;
  }
}
