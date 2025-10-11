import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<User?> getUser(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) return null;

      final data = doc.data()!;
      return User(
        username: data['username'] ?? '',
        email: data['email'] ?? '',
        persona: data['persona'],
      );
    } catch (e) {
      print("❌ Error fetching user: $e");
      return null;
    }
  }
}
