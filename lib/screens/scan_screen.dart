import 'package:flutter/material.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  List<String> scannedRollNumbers = [];

  Future<void> saveAttendanceToFirestore(String rollNo) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("No Firebase user logged in");

    final uid = user.uid;
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    final data = userDoc.data();
    if (data == null) throw Exception("User document not found");

    final facultyName = data['name'] ?? 'Unknown';
    final busNumber = data['busNumber'] ?? 'NA';

    // ✅ Firestore-compatible timestamp
    final timestamp = Timestamp.now();

    // ✅ Save to faculty scan path
    await FirebaseFirestore.instance
        .collection('attendance')
        .doc(facultyName)
        .collection('scans')
        .add({
          'studentId': rollNo,
          'timestamp': timestamp,
          'busNumber': busNumber,
        });

    // ✅ Also save to flat logs
    await FirebaseFirestore.instance.collection('attendance_logs').add({
      'studentId': rollNo,
      'timestamp': timestamp,
      'busNumber': busNumber,
      'scannedBy': facultyName,
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.green,
        content: Text("✅ Attendance saved for: $rollNo"),
      ),
    );
  }

  Future<void> scanAndSave() async {
    try {
      var result = await BarcodeScanner.scan();
      String rollNo = result.rawContent;

      if (!mounted) return;

      if (rollNo.isNotEmpty && !scannedRollNumbers.contains(rollNo)) {
        setState(() {
          scannedRollNumbers.add(rollNo);
        });
        await saveAttendanceToFirestore(rollNo);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.orange,
            content: Text(
              "⚠ Already Scanned or Empty Data",
              style: TextStyle(color: Colors.white),
            ),
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint("❌ Error during scanAndSave: $e");
      debugPrintStack(stackTrace: stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color.fromARGB(255, 33, 7, 80),
          content: Text(
            '❌ Error while scanning',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.indigo.shade900, Colors.indigo.shade300],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),
              Text(
                "🚌 Bus Attendance Scanner",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white.withOpacity(0.9),
                  shadows: [
                    Shadow(
                      offset: const Offset(2, 2),
                      blurRadius: 6,
                      color: Colors.black.withOpacity(0.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: scannedRollNumbers.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 6,
                            offset: const Offset(2, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        title: Text(
                          "Roll No: ${scannedRollNumbers[index]}",
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.check_circle,
                          color: Colors.greenAccent,
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: ElevatedButton(
                  onPressed: scanAndSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.2),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    shadowColor: Colors.black,
                    elevation: 8,
                  ),
                  child: const Text(
                    "📷 Scan & Save to Firestore",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
