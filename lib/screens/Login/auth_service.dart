import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<User?> signInWithGoogle() async {
    if (kIsWeb) {
    
      GoogleAuthProvider googleProvider = GoogleAuthProvider();
      try {
        final userCredential = await _auth.signInWithPopup(googleProvider);
        return userCredential.user;
      } catch (e) {
          print("failed");
        return null;
      }
    } else {
      // ✅ Mobile flow
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      return userCredential.user;
    }
  }
}
