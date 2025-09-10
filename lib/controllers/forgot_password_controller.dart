import 'package:firebase_auth/firebase_auth.dart';

class ForgotPasswordController {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String?> sendPasswordReset(String email) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();

      final methods = await _auth.fetchSignInMethodsForEmail(normalizedEmail);
      print("DEBUG → Providers for $normalizedEmail = $methods");

      if (methods.isEmpty) {
        return "No account found with this email.";
      }

      if (methods.contains("password")) {
        await _auth.sendPasswordResetEmail(email: normalizedEmail);
        return null; // success
      } else {
        return "⚠️ This account uses ${methods.first}. Please sign in with that provider.";
      }
    } on FirebaseAuthException catch (e) {
      print("DEBUG → FirebaseAuthException: ${e.code}, ${e.message}");
      return e.message ?? "Something went wrong.";
    }
  }
}
