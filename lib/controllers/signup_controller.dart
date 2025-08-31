import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SignupController {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final usernameController = TextEditingController();

  /// Sign up with email + password
  Future<String?> signUp() async {
    if (passwordController.text.trim() != confirmPasswordController.text.trim()) {
      return "Passwords do not match";
    }

    try {
      await _auth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      return null; // success
    } on FirebaseAuthException catch (e) {
      return e.message; // Firebase error
    } catch (e) {
      return "An error occurred: $e";
    }
  }

  /// Clean up controllers when widget is disposed
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    usernameController.dispose();
  }
}
