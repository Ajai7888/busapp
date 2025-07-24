import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
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

  /// Signup Method with Role Check and Context for Navigation
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

      if (role == 'admin') {
        // Directly navigate admin to dashboard
        Navigator.pushReplacementNamed(context, '/adminDashboard');
      } else {
        // Faculty needs approval
        await _authService.signOut();
        _user = null;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Signup successful! Please wait for admin approval."),
          ),
        );
        Navigator.pop(context); // Back to login
      }
    }
  }

  /// Logout
  void logout() async {
    await _authService.signOut();
    _user = null;
    notifyListeners();
  }
}
