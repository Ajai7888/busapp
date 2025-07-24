// lib/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/attendance_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> addAttendance(AttendanceRecord record) async {
    await _db.collection('attendance').add(record.toMap());
  }

  Future<List<AttendanceRecord>> fetchAttendanceRecords() async {
    final snapshot = await _db.collection('attendance').get();
    return snapshot.docs
        .map((doc) => AttendanceRecord.fromMap(doc.data()))
        .toList();
  }

  Future<List<Map<String, dynamic>>> fetchPendingApprovals() async {
    final snapshot = await _db
        .collection('users')
        .where('isApproved', isEqualTo: false)
        .get();
    return snapshot.docs.map((doc) => {'uid': doc.id, ...doc.data()}).toList();
  }

  Future<void> approveUser(String uid) async {
    await _db.collection('users').doc(uid).update({'isApproved': true});
  }
}
