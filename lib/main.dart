import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Your app entry point and providers
import 'app.dart';
import 'providers/auth_provider.dart'; // contains authProvider
import 'providers/attendance_provider.dart'; // contains attendanceProvider

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final initialRoute = await getInitialRoute();

  runApp(ProviderScope(child: MyApp(initialRoute: initialRoute)));
}

Future<String> getInitialRoute() async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) return '/login';

  final doc = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .get();

  if (!doc.exists) return '/login';

  final role = doc['role'];
  final isApproved = doc['isApproved'] ?? false;

  if (role == 'admin') return '/admin-dashboard';
  if (role == 'faculty' && isApproved) return '/user-dashboard';

  return '/login';
}
