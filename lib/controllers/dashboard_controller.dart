
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart' as fb;
// import '../models/user.dart';
// import '../models/usage_model.dart';
// import './gamification_controller.dart';

// class DashboardController {
//   final _fs = FirebaseFirestore.instance;
//   final _auth = fb.FirebaseAuth.instance;
//   final GamificationController _gamificationController = GamificationController();

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

//   // New method that integrates gamification with timer stop
//   Future<void> stopTimerAndCheckChallenges(String activity, int seconds, double liters, {String? memberName}) async {
//     // First, log the water usage (your existing functionality)
//     await logWaterUsage(activity, liters, memberName: memberName);
    
//     // Then check for active challenges
//     final activeChallenges = await _gamificationController.getActiveChallenges().first;
    
//     for (final userChallenge in activeChallenges) {
//       final challenges = _gamificationController.getChallengesForPersona(''); // Get all challenges
//       final matchingChallenges = challenges.where((c) => 
//           c.id == userChallenge.challengeId && 
//           (c.activity == activity || c.activity == 'All')
//       ).toList();
      
//       for (final challenge in matchingChallenges) {
//         await _gamificationController.completeChallenge(challenge.id, seconds, liters);
//       }
//     }
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
import 'package:intl/intl.dart';
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
      'timestamp': FieldValue.serverTimestamp(),
      if (memberName != null) 'memberName': memberName,
    });

    // Update user's total usage for quick access
    await _fs.collection('users').doc(authUser.uid).set({
      'totalWaterUsage': FieldValue.increment(liters),
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
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
    return q.docs.fold<double>(0.0, (sum, d) => sum + _safeToDouble(d.data()['liters']));
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
    return _safeToDouble(doc.data()?['moneyBudgetRs']);
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
    return q.docs.fold<double>(0.0, (s, d) => s + _safeToDouble((d.data() as Map<String, dynamic>)['liters']));
  }

  // ---- NEW ECO DASHBOARD FUNCTIONS ----

  // Get comprehensive eco dashboard data
  Future<Map<String, dynamic>> getEcoDashboardData() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      // Get current and last week's data
      final now = DateTime.now();
      final currentWeekStart = _getStartOfWeek(now);
      final lastWeekStart = currentWeekStart.subtract(const Duration(days: 7));
      
      final currentWeekData = await _getWeeklyWaterUsage(user.uid, currentWeekStart);
      final lastWeekData = await _getWeeklyWaterUsage(user.uid, lastWeekStart);
      
      // Calculate metrics - COMPLETELY FIXED: Handle all cases properly
      final thisWeekUsage = _safeToDouble(currentWeekData['totalUsage']) ?? 0.0;
      final lastWeekUsage = _safeToDouble(lastWeekData['totalUsage']) ?? 0.0;
      
      double waterSaved;
      double savingsPercentage;
      
      if (lastWeekUsage > thisWeekUsage) {
        // User saved water this week
        waterSaved = lastWeekUsage - thisWeekUsage;
        savingsPercentage = (waterSaved / lastWeekUsage * 100);
      } else if (lastWeekUsage < thisWeekUsage) {
        // User used more water this week
        waterSaved = 0.0;
        savingsPercentage = -((thisWeekUsage - lastWeekUsage) / lastWeekUsage * 100);
      } else {
        // Usage is the same
        waterSaved = 0.0;
        savingsPercentage = 0.0;
      }
      
      // Calculate environmental impact
      final co2Reduced = _calculateCO2Reduction(waterSaved);
      final moneySaved = _calculateMoneySaved(waterSaved);
      
      // Get user streaks and badges
      final currentStreak = await _getCurrentStreak(user.uid);
      final badges = await _getUserBadges(user.uid);
      final recommendations = await _generateRecommendations(user.uid, thisWeekUsage, lastWeekUsage);

      return {
        'thisWeekUsage': thisWeekUsage,
        'lastWeekUsage': lastWeekUsage,
        'waterSaved': waterSaved,
        'savingsPercentage': savingsPercentage,
        'co2Reduced': co2Reduced,
        'moneySaved': moneySaved,
        'currentStreak': currentStreak,
        'badges': badges,
        'recommendations': recommendations,
        'dailyBreakdown': currentWeekData['dailyBreakdown'],
      };
    } catch (e) {
      print('Error getting eco dashboard data: $e');
      throw e;
    }
  }

  // Get weekly water usage with daily breakdown
  Future<Map<String, dynamic>> _getWeeklyWaterUsage(String userId, DateTime weekStart) async {
    final weekEnd = weekStart.add(const Duration(days: 6));
    
    final query = await _fs
        .collection('users')
        .doc(userId)
        .collection('usage_logs')
        .where('date', isGreaterThanOrEqualTo: weekStart.toIso8601String())
        .where('date', isLessThanOrEqualTo: weekEnd.toIso8601String())
        .get();

    double totalUsage = 0.0;
    final dailyBreakdown = <String, double>{};

    for (final doc in query.docs) {
      final data = doc.data();
      final usage = _safeToDouble(data['liters']) ?? 0.0;
      totalUsage += usage;
      
      // Add to daily breakdown
      final dateString = data['date'] as String?;
      if (dateString != null) {
        try {
          final date = DateTime.parse(dateString);
          final dayKey = DateFormat('EEE').format(date);
          dailyBreakdown[dayKey] = (_safeToDouble(dailyBreakdown[dayKey]) ?? 0.0) + usage;
        } catch (e) {
          print('Error parsing date: $e');
        }
      }
    }

    return {
      'totalUsage': totalUsage,
      'dailyBreakdown': dailyBreakdown,
    };
  }

  // Get current conservation streak
  Future<int> _getCurrentStreak(String userId) async {
    final now = DateTime.now();
    var currentDate = DateTime(now.year, now.month, now.day);
    var streak = 0;
    
    while (streak < 365) { // Limit to 1 year max
      final dayStart = currentDate;
      final dayEnd = currentDate.add(const Duration(days: 1));
      
      final query = await _fs
          .collection('users')
          .doc(userId)
          .collection('usage_logs')
          .where('date', isGreaterThanOrEqualTo: dayStart.toIso8601String())
          .where('date', isLessThan: dayEnd.toIso8601String())
          .get();

      final dailyUsage = query.docs.fold<double>(0.0, (sum, doc) {
        final data = doc.data();
        return sum + (_safeToDouble(data['liters']) ?? 0.0);
      });
      
      // Check if usage is below conservation threshold (e.g., 100L per day)
      if (dailyUsage <= 100.0) {
        streak++;
        currentDate = currentDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    
    return streak;
  }

  // Get user's earned badges
  Future<List<String>> _getUserBadges(String userId) async {
    final userDoc = await _fs.collection('users').doc(userId).get();
    final badges = userDoc.data()?['badges'] ?? <String>[];
    return List<String>.from(badges);
  }

  // Generate personalized recommendations
  Future<List<String>> _generateRecommendations(String userId, double thisWeekUsage, double lastWeekUsage) async {
    final recommendations = <String>[];
    
    // Get usage patterns for better recommendations
    final usagePatterns = await _getUsagePatterns(userId);
    final avgDailyUsage = thisWeekUsage / 7;

    // Generate recommendations based on usage
    if (avgDailyUsage > 150) {
      recommendations.add('Consider shorter showers to save up to 30L per day');
    }
    
    if (usagePatterns['peakHours']?.contains('morning') == true) {
      recommendations.add('Spread out water usage to avoid morning peak hours');
    }
    
    if (thisWeekUsage > lastWeekUsage && lastWeekUsage > 0) {
      final increase = ((thisWeekUsage - lastWeekUsage) / lastWeekUsage * 100);
      recommendations.add('Your usage increased by ${increase.toStringAsFixed(1)}% this week. Try to reduce by 15% next week');
    } else if (lastWeekUsage > thisWeekUsage && lastWeekUsage > 0) {
      final reduction = ((lastWeekUsage - thisWeekUsage) / lastWeekUsage * 100);
      recommendations.add('Great job! You reduced usage by ${reduction.toStringAsFixed(1)}%');
    }

    // Check for potential leaks
    if (_safeToDouble(usagePatterns['nightUsage'])! > 20) {
      recommendations.add('High nighttime usage detected. Check for running toilets or leaks');
    }

    // Efficiency recommendations
    recommendations.add('Install low-flow showerheads to save 15L per shower');
    recommendations.add('Fix dripping faucets - they can waste 20L daily');

    return recommendations.take(3).toList();
  }

  // Get usage patterns for recommendations
  Future<Map<String, dynamic>> _getUsagePatterns(String userId) async {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    
    final query = await _fs
        .collection('users')
        .doc(userId)
        .collection('usage_logs')
        .where('date', isGreaterThanOrEqualTo: weekAgo.toIso8601String())
        .get();

    double nightUsage = 0.0;
    final hourCount = <int, int>{};

    for (final doc in query.docs) {
      final data = doc.data();
      final dateString = data['date'] as String?;
      if (dateString != null) {
        try {
          final timestamp = DateTime.parse(dateString);
          final hour = timestamp.hour;
          
          // Count night usage (10 PM - 6 AM)
          if (hour >= 22 || hour < 6) {
            nightUsage += _safeToDouble(data['liters']) ?? 0.0;
          }
          
          // Track usage by hour
          hourCount[hour] = (hourCount[hour] ?? 0) + 1;
        } catch (e) {
          print('Error parsing timestamp: $e');
        }
      }
    }

    // Find peak hours
    String peakTime = 'morning';
    if (hourCount.isNotEmpty) {
      final peakHour = hourCount.entries.reduce((a, b) => a.value > b.value ? a : b).key;
      if (peakHour >= 12 && peakHour < 18) {
        peakTime = 'afternoon';
      } else if (peakHour >= 18) {
        peakTime = 'evening';
      }
    }

    return {
      'nightUsage': nightUsage,
      'peakHours': peakTime,
    };
  }

  // Calculate CO2 reduction from water savings
  double _calculateCO2Reduction(double waterSaved) {
    // Rough estimate: 1m³ water = 0.3 kg CO2 for treatment and distribution
    return (waterSaved / 1000) * 0.3;
  }

  // Calculate money saved from water savings
  double _calculateMoneySaved(double waterSaved) {
    return waterSaved * rsPerLiter;
  }

  // Helper function to get start of week (Monday)
  DateTime _getStartOfWeek(DateTime date) {
    final weekday = date.weekday;
    return date.subtract(Duration(days: weekday - 1));
  }

  // Get monthly trend data for charts
  Future<Map<String, double>> getMonthlyTrend() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final now = DateTime.now();
    final monthlyData = <String, double>{};
    
    for (int i = 0; i < 6; i++) {
      final monthStart = DateTime(now.year, now.month - i, 1);
      final monthEnd = DateTime(now.year, now.month - i + 1, 1).subtract(const Duration(days: 1));
      
      final query = await _fs
          .collection('users')
          .doc(user.uid)
          .collection('usage_logs')
          .where('date', isGreaterThanOrEqualTo: monthStart.toIso8601String())
          .where('date', isLessThanOrEqualTo: monthEnd.toIso8601String())
          .get();

      final monthlyUsage = query.docs.fold<double>(0.0, (sum, doc) {
        final data = doc.data();
        return sum + (_safeToDouble(data['liters']) ?? 0.0);
      });
      
      final monthKey = DateFormat('MMM').format(monthStart);
      monthlyData[monthKey] = monthlyUsage;
    }
    
    return monthlyData;
  }

  // Check and award badges based on user achievements
  Future<void> _checkAndAwardBadges(String userId) async {
    final userDoc = await _fs.collection('users').doc(userId).get();
    final currentBadges = List<String>.from(userDoc.data()?['badges'] ?? []);
    final newBadges = <String>[];

    // Get user stats
    final totalUsage = _safeToDouble(userDoc.data()?['totalWaterUsage']) ?? 0.0;
    final streak = await _getCurrentStreak(userId);

    // Award badges based on criteria
    if (streak >= 7 && !currentBadges.contains('Consistency King')) {
      newBadges.add('Consistency King');
    }
    
    if (totalUsage < 5000 && !currentBadges.contains('Water Saver')) {
      newBadges.add('Water Saver');
    }
    
    if (streak >= 30 && !currentBadges.contains('Eco Warrior')) {
      newBadges.add('Eco Warrior');
    }

    // Add new badges if any
    if (newBadges.isNotEmpty) {
      await _fs
          .collection('users')
          .doc(userId)
          .set({
            'badges': FieldValue.arrayUnion(newBadges),
          }, SetOptions(merge: true));
    }
  }

  // Safe conversion helper method
  double _safeToDouble(dynamic value) {
    if (value == null) return 0.0;
    
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    if (value is num) return value.toDouble();
    
    return 0.0;
  }

  // ---- EXISTING METHODS (unchanged) ----
  Future getMonthlyTotal() async {
    // Your existing implementation
  }

  Future getUsageHistory() async {
    // Your existing implementation
  }
}