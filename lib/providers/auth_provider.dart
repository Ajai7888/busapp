import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

import '../services/auth_service.dart';
import '../models/user_model.dart';

/// ✅ ChangeNotifier Provider for Riverpod
final authProvider = ChangeNotifierProvider<AppAuthProvider>((ref) {
  return AppAuthProvider();
});

class AppAuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  AppUser? _user;
  AppUser? get user => _user;

  /// Login Method
  Future<void> login(String email, String password) async {
    final firebaseUser = await _authService.signIn(email, password);
    if (firebaseUser != null) {
      final userData = await _authService.getUserDetails(firebaseUser.uid);
      if (userData != null) {
        if (userData.role == 'admin' || userData.isApproved) {
          _user = userData;
          notifyListeners();
        } else {
          await _authService.signOut();
          throw Exception("Your account is awaiting admin approval.");
        }
      }
    }
  }

  /// Signup Method with Role Check and Safe Navigation
  Future<void> signup(
    String name,
    String email,
    String password,
    String role,
    BuildContext context,
  ) async {
    final firebaseUser = await _authService.signUp(name, email, password, role);

    if (firebaseUser != null) {
      _user = await _authService.getUserDetails(firebaseUser.uid);
      notifyListeners();

      // Sign out and reset state after signup
      await _authService.signOut();
      _user = null;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Signup successful! Please login.")),
      );

      // ✅ Go to login screen using GoRouter
      if (context.mounted) {
        context.go('/login');
      }
    }
  }

  /// Logout Method
  Future<void> logout() async {
    await _authService.signOut();
    _user = null;
    notifyListeners();
  }
}
