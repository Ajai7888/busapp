// lib/services/excel_export_service.dart
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as excel;

class ExcelExportService {
  static Future<bool> exportRawMapList(
    List<Map<String, dynamic>> records,
  ) async {
    final workbook = excel.Workbook();
    final sheet = workbook.worksheets[0];

    // Set headers
    sheet.getRangeByName('A1').setText('Student ID');
    sheet.getRangeByName('B1').setText('Bus Number');
    sheet.getRangeByName('C1').setText('Timestamp');

    // Populate rows
    for (int i = 0; i < records.length; i++) {
      final row = i + 2;
      sheet
          .getRangeByName('A$row')
          .setText(records[i]['studentId']?.toString() ?? '');
      sheet
          .getRangeByName('B$row')
          .setText(records[i]['busNumber']?.toString() ?? '');
      sheet
          .getRangeByName('C$row')
          .setText(records[i]['timestamp']?.toString() ?? '');
    }

    // Save file
    final List<int> bytes = workbook.saveAsStream();
    workbook.dispose();

    final directory = await getExternalStorageDirectory();
    final path = '${directory!.path}/attendance_export.xlsx';
    final file = File(path);
    await file.writeAsBytes(bytes, flush: true);

    return true;
  }
}
