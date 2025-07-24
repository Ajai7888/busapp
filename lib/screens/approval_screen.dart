import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ApprovalScreen extends StatelessWidget {
  const ApprovalScreen({super.key});

  Future<void> approveUser(String uid) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'isApproved': true,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pending Approvals")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('isApproved', isEqualTo: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final users = snapshot.data!.docs;

          if (users.isEmpty) {
            return const Center(child: Text("No pending approvals"));
          }

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return ListTile(
                title: Text(user['name']),
                subtitle: Text(user['email']),
                trailing: ElevatedButton(
                  onPressed: () async {
                    await approveUser(user.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("User approved")),
                    );
                  },
                  child: const Text("Approve"),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
