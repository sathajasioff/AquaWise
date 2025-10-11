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
      if (user == null) {
        print("❌ No user logged in");
        return null;
      }

      print("🔄 Uploading profile photo for user: ${user.uid}");
      final ref = _storage.ref().child('profile_photos/${user.uid}.jpg');
      
      // Upload the file
      final uploadTask = await ref.putFile(imageFile);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      
      print("✅ Profile photo uploaded successfully: $downloadUrl");
      return downloadUrl;
    } catch (e) {
      print("❌ Error uploading image: $e");
      return null;
    }
  }

  /// Updates Firestore with new info - FIXED VERSION
  Future<bool> updateUserProfile({
    String? username,
    String? photoUrl,
    String? themePreference,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print("❌ No user logged in for profile update");
        return false;
      }

      print("🔄 Updating profile for user: ${user.uid}");
      print("📝 Update data - username: $username, photoUrl: $photoUrl, theme: $themePreference");

      // Create update data - only include non-null values
      final Map<String, dynamic> updateData = {};
      
      if (username != null && username.isNotEmpty) {
        updateData['username'] = username;
        print("✅ Adding username to update: $username");
      }
      
      if (photoUrl != null) {
        updateData['photoUrl'] = photoUrl;
        print("✅ Adding photoUrl to update: $photoUrl");
      }
      
      if (themePreference != null) {
        updateData['theme'] = themePreference;
        print("✅ Adding theme to update: $themePreference");
      }

      // Check if we have any data to update
      if (updateData.isEmpty) {
        print("⚠️ No data to update");
        return true; // Nothing to update, but not an error
      }

      print("📤 Sending update to Firestore: $updateData");
      
      // Update Firestore
      await _firestore.collection('users').doc(user.uid).update(updateData);
      
      print("✅ Profile updated successfully in Firestore");
      return true;
    } catch (e) {
      print("❌ Error updating profile in Firestore: $e");
      return false;
    }
  }

  /// Fetch current data for prefill
  Future<Map<String, dynamic>?> getCurrentProfile() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      print("🔄 Fetching profile data for user: ${user.uid}");
      final doc = await _firestore.collection('users').doc(user.uid).get();
      
      if (doc.exists) {
        final data = doc.data();
        print("✅ Profile data fetched: $data");
        return data;
      } else {
        print("❌ No profile document found for user: ${user.uid}");
        return null;
      }
    } catch (e) {
      print("❌ Error fetching profile: $e");
      return null;
    }
  }

  /// Delete profile photo from storage
  Future<void> deleteProfilePhoto() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final ref = _storage.ref().child('profile_photos/${user.uid}.jpg');
      await ref.delete();
      print("✅ Profile photo deleted from storage");
    } catch (e) {
      print("❌ Error deleting profile photo: $e");
    }
  }
}