import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class EditProfileController {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  /// Uploads new profile photo to Firebase Storage
  Future<String?> uploadProfilePhoto(File imageFile) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final ref = _storage.ref().child('profile_photos/${user.uid}.jpg');
      await ref.putFile(imageFile);
      return await ref.getDownloadURL();
    } catch (e) {
      print("Error uploading image: $e");
      return null;
    }
  }

  /// Updates Firestore with new info
  Future<void> updateUserProfile({
    String? username,
    String? photoUrl,
    String? themePreference,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final data = <String, dynamic>{};
      if (username != null) data['username'] = username;
      if (photoUrl != null) data['photoUrl'] = photoUrl;
      if (themePreference != null) data['theme'] = themePreference;

      await _firestore.collection('users').doc(user.uid).update(data);
    } catch (e) {
      print("Error updating profile: $e");
    }
  }

  /// Fetch current data for prefill
  Future<Map<String, dynamic>?> getCurrentProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc = await _firestore.collection('users').doc(user.uid).get();
    return doc.data();
  }
}
