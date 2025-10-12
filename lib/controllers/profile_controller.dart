import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/usage_model.dart';

class ProfileController {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  // Fetch user's usage history
  Stream<List<WaterUsage>> getUserUsageHistory() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('usage_logs')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => WaterUsage.fromMap(doc.id, doc.data())).toList());
  }

  // Fetch total water used
  Future<double> getTotalWaterUsed() async {
    final user = _auth.currentUser;
    if (user == null) return 0;

    final query = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('usage_logs')
        .get();

    double total = 0;
    for (var doc in query.docs) {
      total += (doc.data()['liters'] ?? 0).toDouble();
    }
    return total;
  }
}
