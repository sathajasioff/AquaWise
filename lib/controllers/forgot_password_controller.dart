import 'package:firebase_auth/firebase_auth.dart';

class ForgotPasswordController {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String?> sendPasswordReset(String email) async {
    try {
      final normalizedEmail = email.trim();
      
      print("🔄 Attempting to send reset email to: '$normalizedEmail'");

      // Try to send reset email directly first
      await _auth.sendPasswordResetEmail(email: normalizedEmail);
      
      print("✅ Password reset email sent successfully");
      return null; // Success
      
    } on FirebaseAuthException catch (e) {
      print("🔴 FirebaseAuthException: ${e.code}, ${e.message}");
      
      switch (e.code) {
        case 'invalid-email':
          return "Please enter a valid email address.";
        case 'user-not-found':
          // Let's debug why this is happening
          print("🔴 USER-NOT-FOUND for: '$email'");
          return "No account found with this email address. Please check if you used a different email or signed up with Google/Facebook.";
        case 'too-many-requests':
          return "Too many attempts. Please try again in a few minutes.";
        case 'network-request-failed':
          return "Please check your internet connection.";
        default:
          return "Unable to send reset email: ${e.message}";
      }
    } catch (e) {
      print("🔴 Unexpected error: $e");
      return "An error occurred. Please try again.";
    }
  }
}