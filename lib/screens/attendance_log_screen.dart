// lib/screens/attendance_log_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class AttendanceLogScreen extends StatelessWidget {
  const AttendanceLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser?.uid)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final scannedBy = snapshot.data!.get('name') ?? 'Unknown';

        final now = DateTime.now().toUtc();
        final startOfDay = DateTime.utc(now.year, now.month, now.day);
        final endOfDay = startOfDay.add(const Duration(days: 1));

        final stream = FirebaseFirestore.instance
            .collection('attendance_logs')
            .where(
              'timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
            )
            .where('timestamp', isLessThan: Timestamp.fromDate(endOfDay))
            .where('scannedBy', isEqualTo: scannedBy)
            .orderBy('timestamp', descending: true)
            .snapshots();

        return Scaffold(
          appBar: AppBar(
            title: const Text("Today's Attendance Logs"),
            backgroundColor: Colors.indigo,
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: stream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("No logs for today."));
              }

              final docs = snapshot.data!.docs;

              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;

                  final studentId = data['studentId'] ?? 'N/A';
                  final busNumber = data['busNumber'] ?? 'N/A';
                  final scannedBy = data['scannedBy'] ?? 'N/A';
                  final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
                  final timeString = timestamp != null
                      ? DateFormat('hh:mm a').format(timestamp)
                      : 'Unknown';

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.person, color: Colors.indigo),
                      title: Text("Student ID: $studentId"),
                      subtitle: Text(
                        "Bus: $busNumber\n"
                        "Scanned By: $scannedBy\n"
                        "Time: $timeString",
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
