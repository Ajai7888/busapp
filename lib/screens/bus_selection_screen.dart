import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BusSelectionScreen extends StatelessWidget {
  final List<String> busNumbers = [
    'TN22 AA1234',
    'TN22 AB5678',
    'TN22 AC9101',
    'TN22 AD2345',
    'TN22 AE6789',
    'TN22 AF1122',
    'TN22 AG3344',
    'TN22 AH5566',
    'TN22 AJ7788',
    'TN22 AK9900',
    'TN22 AL1212',
    'TN22 AM3434',
    'TN22 AN5656',
    'TN22 AP7878',
    'TN22 AR9090',
    'TN22 AS0101',
    'TN22 AT2323',
    'TN22 AU4545',
    'TN22 AV6767',
    'TN22 AW8989',
    'TN22 AX1111',
    'TN22 AY2222',
    'TN22 AZ3333',
    'TN22 BA4444',
    'TN22 BB5555',
    'TN22 BC6666',
    'TN22 BD7777',
    'TN22 BE8888',
    'TN22 BF9999',
    'TN22 BG0001',
    'TN22 BH1234',
    'TN22 BJ2345',
    'TN22 BK3456',
    'TN22 BL4567',
    'TN22 BM5678',
    'TN22 BN6789',
    'TN22 BP7890',
    'TN22 BR8901',
    'TN22 BS9012',
    'TN22 BT0123',
    'TN22 BU1234',
    'TN22 BV2345',
    'TN22 BW3456',
    'TN22 BX4567',
    'TN22 BY5678',
    'TN22 BZ6789',
    'TN22 CA7890',
    'TN22 CB8901',
    'TN22 CC9012',
    'TN22CD0123',
  ];

  Future<void> _selectBus(BuildContext context, String selectedBus) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'busNumber': selectedBus,
      });

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Bus number "$selectedBus" assigned!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Your Bus Number')),
      body: ListView.builder(
        itemCount: busNumbers.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(busNumbers[index]),
            onTap: () => _selectBus(context, busNumbers[index]),
          );
        },
      ),
    );
  }
}
