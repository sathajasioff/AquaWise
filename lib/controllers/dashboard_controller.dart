import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import '../models/user.dart';
import '../models/usage_model.dart';

class DashboardController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// ✅ Fetch logged-in user info from Firestore
  Future<User?> fetchUser() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) {
        print("⚠️ Firestore: User document not found for ${user.uid}");
        return null;
      }

      return User.fromMap(doc.data()!, doc.id);
    } catch (e) {
      print('❌ Error fetching user: $e');
      return null;
    }
  }

  /// ✅ Log manual water usage (adds to subcollection)
  Future<void> logWaterUsage(String activity, double liters) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('usage_logs')
          .add({
        'activity': activity,
        'liters': liters,
        'date': Timestamp.now(),
      });

      print("✅ Logged $activity: $liters L");
    } catch (e) {
      print('❌ Error logging usage: $e');
    }
  }

  /// ✅ Real-time usage logs stream
  Stream<List<WaterUsage>> getUsageLogs() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('usage_logs')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WaterUsage.fromMap(doc.data() as String, doc.id as Map<String, dynamic>))
            .toList());
  }

  /// ✅ Monthly total calculation
  Future<double> getMonthlyTotal() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 0.0;

      final start = Timestamp.fromDate(DateTime(DateTime.now().year, DateTime.now().month, 1));
      final end = Timestamp.fromDate(DateTime(DateTime.now().year, DateTime.now().month + 1, 1));

      final query = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('usage_logs')
          .where('date', isGreaterThanOrEqualTo: start)
          .where('date', isLessThan: end)
          .get();

      double total = 0;
      for (var doc in query.docs) {
        total += (doc['liters'] ?? 0).toDouble();
      }

      print("📊 Monthly total = $total L");
      return total;
    } catch (e) {
      print('❌ Error calculating monthly total: $e');
      return 0.0;
    }
  }
}
