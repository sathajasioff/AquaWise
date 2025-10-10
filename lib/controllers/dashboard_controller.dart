// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart' as fb;
// import '../models/user.dart';
// import '../models/usage_model.dart';

// class DashboardController {
//   final _fs = FirebaseFirestore.instance;
//   final _auth = fb.FirebaseAuth.instance;

//   // ---- USERS ----
//   Future<User?> fetchUser() async {
//     final authUser = _auth.currentUser;
//     if (authUser == null) return null;
//     final snap = await _fs.collection('users').doc(authUser.uid).get();
//     if (!snap.exists) return null;
//     return User.fromMap(snap.data()!, snap.id);
//   }

//   // ---- USAGE LOGS ----
//   Future<void> logWaterUsage(String activity, double liters, {String? memberName}) async {
//     final authUser = _auth.currentUser;
//     if (authUser == null) return;
//     final col = _fs.collection('users').doc(authUser.uid).collection('usage_logs');
//     await col.add({
//       'activity': activity,
//       'liters': liters,
//       'date': DateTime.now().toIso8601String(),
//       if (memberName != null) 'memberName': memberName,
//     });
//   }

//   Stream<List<WaterUsage>> usageStream({DateTime? from, DateTime? to}) {
//     final authUser = _auth.currentUser!;
//     Query q = _fs.collection('users').doc(authUser.uid).collection('usage_logs').orderBy('date', descending: true);
//     if (from != null) q = q.where('date', isGreaterThanOrEqualTo: from.toIso8601String());
//     if (to != null)   q = q.where('date', isLessThan: to.toIso8601String());
//     return q.snapshots().map((s) => s.docs.map((d) => WaterUsage.fromMap(d.id, d.data() as Map<String, dynamic>)).toList());
//   }

//   Future<double> monthlyTotalLiters({DateTime? month}) async {
//     final now = month ?? DateTime.now();
//     final start = DateTime(now.year, now.month, 1);
//     final end = DateTime(now.year, now.month + 1, 1);
//     final authUser = _auth.currentUser!;
//     final q = await _fs.collection('users').doc(authUser.uid).collection('usage_logs')
//       .where('date', isGreaterThanOrEqualTo: start.toIso8601String())
//       .where('date', isLessThan: end.toIso8601String())
//       .get();
//     // ignore: avoid_types_as_parameter_names
//     return q.docs.fold<double>(0.0, (sum, d) => sum + (d.data()['liters'] as num).toDouble());
//   }

//   // ---- FAMILY (aggregate by memberName) ----
//   Stream<Map<String, double>> familyBreakdownThisMonth() {
//     final now = DateTime.now();
//     final start = DateTime(now.year, now.month, 1);
//     final end = DateTime(now.year, now.month + 1, 1);
//     return usageStream(from: start, to: end).map((logs) {
//       final map = <String, double>{};
//       for (final l in logs) {
//         final key = (l.memberName ?? 'Me');
//         map[key] = (map[key] ?? 0) + l.liters;
//       }
//       return map;
//     });
//   }

//   // ---- BUDGET / BILL ----
//   // Simple tariff (tune or load from Firestore settings if you want)
//   static const double rsPerLiter = 0.02; // Rs 0.02 per liter (example)
//   double estimateBillRs(double liters) => liters * rsPerLiter;

//   Future<double?> getMoneyBudgetRs() async {
//     final u = _auth.currentUser;
//     if (u == null) return null;
//     final doc = await _fs.collection('users').doc(u.uid).get();
//     return (doc.data()?['moneyBudgetRs'])?.toDouble();
//   }

//   Future<void> setMoneyBudgetRs(double rs) async {
//     final u = _auth.currentUser;
//     if (u == null) return;
//     await _fs.collection('users').doc(u.uid).set({'moneyBudgetRs': rs}, SetOptions(merge: true));
//   }

//   // ---- WEEKLY COMPARISON (for eco) ----
//   Future<Map<String, double>> thisVsLastWeek() async {
//     final now = DateTime.now();
//     final startThis = now.subtract(Duration(days: now.weekday - 1)); // Monday
//     final endThis = startThis.add(const Duration(days: 7));
//     final startLast = startThis.subtract(const Duration(days: 7));
//     final endLast = startThis;

//     final totThis = await _rangeTotal(startThis, endThis);
//     final totLast = await _rangeTotal(startLast, endLast);
//     return {'this': totThis, 'last': totLast};
//   }

//   Future<double> _rangeTotal(DateTime from, DateTime to) async {
//     final u = _auth.currentUser!;
//     final q = await _fs.collection('users').doc(u.uid).collection('usage_logs')
//       .where('date', isGreaterThanOrEqualTo: from.toIso8601String())
//       .where('date', isLessThan: to.toIso8601String())
//       .get();
//     return q.docs.fold<double>(0.0, (s, d) => s + ((d.data() as Map<String, dynamic>)['liters'] ?? 0).toDouble());
//   }

//   Future getMonthlyTotal() async {}

//   Future getUsageHistory() async {}
// }

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../models/user.dart';
import '../models/usage_model.dart';
import './gamification_controller.dart';

class DashboardController {
  final _fs = FirebaseFirestore.instance;
  final _auth = fb.FirebaseAuth.instance;
  final GamificationController _gamificationController = GamificationController();

  // ---- USERS ----
  Future<User?> fetchUser() async {
    final authUser = _auth.currentUser;
    if (authUser == null) return null;
    final snap = await _fs.collection('users').doc(authUser.uid).get();
    if (!snap.exists) return null;
    return User.fromMap(snap.data()!, snap.id);
  }

  // ---- USAGE LOGS ----
  Future<void> logWaterUsage(String activity, double liters, {String? memberName}) async {
    final authUser = _auth.currentUser;
    if (authUser == null) return;
    final col = _fs.collection('users').doc(authUser.uid).collection('usage_logs');
    await col.add({
      'activity': activity,
      'liters': liters,
      'date': DateTime.now().toIso8601String(),
      if (memberName != null) 'memberName': memberName,
    });
  }

  // New method that integrates gamification with timer stop
  Future<void> stopTimerAndCheckChallenges(String activity, int seconds, double liters, {String? memberName}) async {
    // First, log the water usage (your existing functionality)
    await logWaterUsage(activity, liters, memberName: memberName);
    
    // Then check for active challenges
    final activeChallenges = await _gamificationController.getActiveChallenges().first;
    
    for (final userChallenge in activeChallenges) {
      final challenges = _gamificationController.getChallengesForPersona(''); // Get all challenges
      final matchingChallenges = challenges.where((c) => 
          c.id == userChallenge.challengeId && 
          (c.activity == activity || c.activity == 'All')
      ).toList();
      
      for (final challenge in matchingChallenges) {
        await _gamificationController.completeChallenge(challenge.id, seconds, liters);
      }
    }
  }

  Stream<List<WaterUsage>> usageStream({DateTime? from, DateTime? to}) {
    final authUser = _auth.currentUser!;
    Query q = _fs.collection('users').doc(authUser.uid).collection('usage_logs').orderBy('date', descending: true);
    if (from != null) q = q.where('date', isGreaterThanOrEqualTo: from.toIso8601String());
    if (to != null)   q = q.where('date', isLessThan: to.toIso8601String());
    return q.snapshots().map((s) => s.docs.map((d) => WaterUsage.fromMap(d.id, d.data() as Map<String, dynamic>)).toList());
  }

  Future<double> monthlyTotalLiters({DateTime? month}) async {
    final now = month ?? DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 1);
    final authUser = _auth.currentUser!;
    final q = await _fs.collection('users').doc(authUser.uid).collection('usage_logs')
      .where('date', isGreaterThanOrEqualTo: start.toIso8601String())
      .where('date', isLessThan: end.toIso8601String())
      .get();
    // ignore: avoid_types_as_parameter_names
    return q.docs.fold<double>(0.0, (sum, d) => sum + (d.data()['liters'] as num).toDouble());
  }

  // ---- FAMILY (aggregate by memberName) ----
  Stream<Map<String, double>> familyBreakdownThisMonth() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 1);
    return usageStream(from: start, to: end).map((logs) {
      final map = <String, double>{};
      for (final l in logs) {
        final key = (l.memberName ?? 'Me');
        map[key] = (map[key] ?? 0) + l.liters;
      }
      return map;
    });
  }

  // ---- BUDGET / BILL ----
  // Simple tariff (tune or load from Firestore settings if you want)
  static const double rsPerLiter = 0.02; // Rs 0.02 per liter (example)
  double estimateBillRs(double liters) => liters * rsPerLiter;

  Future<double?> getMoneyBudgetRs() async {
    final u = _auth.currentUser;
    if (u == null) return null;
    final doc = await _fs.collection('users').doc(u.uid).get();
    return (doc.data()?['moneyBudgetRs'])?.toDouble();
  }

  Future<void> setMoneyBudgetRs(double rs) async {
    final u = _auth.currentUser;
    if (u == null) return;
    await _fs.collection('users').doc(u.uid).set({'moneyBudgetRs': rs}, SetOptions(merge: true));
  }

  // ---- WEEKLY COMPARISON (for eco) ----
  Future<Map<String, double>> thisVsLastWeek() async {
    final now = DateTime.now();
    final startThis = now.subtract(Duration(days: now.weekday - 1)); // Monday
    final endThis = startThis.add(const Duration(days: 7));
    final startLast = startThis.subtract(const Duration(days: 7));
    final endLast = startThis;

    final totThis = await _rangeTotal(startThis, endThis);
    final totLast = await _rangeTotal(startLast, endLast);
    return {'this': totThis, 'last': totLast};
  }

  Future<double> _rangeTotal(DateTime from, DateTime to) async {
    final u = _auth.currentUser!;
    final q = await _fs.collection('users').doc(u.uid).collection('usage_logs')
      .where('date', isGreaterThanOrEqualTo: from.toIso8601String())
      .where('date', isLessThan: to.toIso8601String())
      .get();
    return q.docs.fold<double>(0.0, (s, d) => s + ((d.data() as Map<String, dynamic>)['liters'] ?? 0).toDouble());
  }

  Future getMonthlyTotal() async {}

  Future getUsageHistory() async {}
}