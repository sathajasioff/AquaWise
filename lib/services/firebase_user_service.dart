import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseUserService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Initialize user data when they first sign up
  static Future<void> initializeUserData(String userId, String email, String displayName) async {
    try {
      final today = DateTime.now();
      final dateKey = '${today.year}-${today.month}-${today.day}';
      
      await _firestore.collection('users').doc(userId).set({
        'email': email,
        'displayName': displayName,
        'dailyUsage': {
          dateKey: 0.0 // Initialize with 0 for today
        },
        'totalSaved': 0,
        'points': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)); // Use merge to not overwrite existing data
      
      print('✅ User data initialized for: $email');
    } catch (e) {
      print('❌ Error initializing user data: $e');
      rethrow;
    }
  }

  // Get current user data
  static Future<Map<String, dynamic>?> getCurrentUserData() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        return doc.data();
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  // Ensure dailyUsage field exists and get today's water usage
  static Future<double> getTodayWaterUsage() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final today = DateTime.now();
        final dateKey = '${today.year}-${today.month}-${today.day}';
        
        final doc = await _firestore.collection('users').doc(user.uid).get();
        final data = doc.data();
        
        // If no document exists, create it
        if (!doc.exists) {
          print('📝 Creating new user document...');
          await initializeUserData(
            user.uid, 
            user.email ?? 'user@example.com', 
            user.displayName ?? user.email?.split('@').first ?? 'User'
          );
          return 0.0;
        }
        
        // If document exists but no dailyUsage field, add it
        if (data == null || !data.containsKey('dailyUsage')) {
          print('📝 Adding dailyUsage field to existing user document...');
          await _firestore.collection('users').doc(user.uid).set({
            'dailyUsage': {
              dateKey: 0.0
            },
            'lastUpdated': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          return 0.0;
        }
        
        final dailyUsage = data['dailyUsage'] as Map<String, dynamic>?;
        
        // If dailyUsage exists but no entry for today, add it
        if (dailyUsage == null || !dailyUsage.containsKey(dateKey)) {
          print('📝 Adding today\'s date to dailyUsage...');
          await _firestore.collection('users').doc(user.uid).update({
            'dailyUsage.$dateKey': 0.0,
            'lastUpdated': FieldValue.serverTimestamp(),
          });
          return 0.0;
        }
        
        // Return the actual usage
        final usage = (dailyUsage[dateKey] as num).toDouble();
        print('✅ Retrieved water usage: $usage liters for $dateKey');
        return usage;
      }
      return 0.0;
    } catch (e) {
      print('❌ Error getting water usage: $e');
      return 0.0;
    }
  }

  // Update user's daily water usage
  static Future<void> updateDailyWaterUsage(double liters) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final today = DateTime.now();
        final dateKey = '${today.year}-${today.month}-${today.day}';
        
        print('📝 Updating water usage to: $liters liters for $dateKey');
        
        await _firestore.collection('users').doc(user.uid).set({
          'dailyUsage': {
            dateKey: liters
          },
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        
        print('✅ Water usage updated successfully');
      }
    } catch (e) {
      print('❌ Error updating water usage: $e');
      rethrow;
    }
  }

  // Add manual water usage
  static Future<void> addManualWaterUsage(double liters) async {
    try {
      await updateDailyWaterUsage(liters);
      print('✅ Manual water usage added: $liters liters');
    } catch (e) {
      print('❌ Error adding manual water usage: $e');
      rethrow;
    }
  }

  // Get water usage history
  static Future<Map<DateTime, double>> getWaterUsageHistory() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        final data = doc.data();
        
        if (data != null && data.containsKey('dailyUsage')) {
          final dailyUsage = data['dailyUsage'] as Map<String, dynamic>?;
          final history = <DateTime, double>{};
          
          if (dailyUsage != null) {
            for (final entry in dailyUsage.entries) {
              final parts = entry.key.split('-');
              final date = DateTime(
                int.parse(parts[0]),
                int.parse(parts[1]),
                int.parse(parts[2]),
              );
              history[date] = (entry.value as num).toDouble();
            }
          }
          return history;
        }
      }
      return {};
    } catch (e) {
      print('Error getting water usage history: $e');
      return {};
    }
  }

  // Get user's display name
  static Future<String> getUserDisplayName() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        final data = doc.data();
        
        if (data != null && data.containsKey('displayName')) {
          return data['displayName'] ?? 'User';
        }
        
        // Fallback to email name
        final email = user.email ?? '';
        return email.split('@').first;
      }
      return 'User';
    } catch (e) {
      print('Error getting user name: $e');
      return 'User';
    }
  }

  // Debug method to check user data
  static Future<void> debugUserData() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        print('🔍 DEBUG: Current User UID: ${user.uid}');
        print('🔍 DEBUG: Current User Email: ${user.email}');
        
        final doc = await _firestore.collection('users').doc(user.uid).get();
        print('🔍 DEBUG: User document exists: ${doc.exists}');
        
        if (doc.exists) {
          final data = doc.data();
          print('🔍 DEBUG: User data: $data');
          
          final today = DateTime.now();
          final dateKey = '${today.year}-${today.month}-${today.day}';
          print('🔍 DEBUG: Looking for date key: $dateKey');
          
          if (data != null && data.containsKey('dailyUsage')) {
            final dailyUsage = data['dailyUsage'] as Map<String, dynamic>?;
            print('🔍 DEBUG: Daily usage map: $dailyUsage');
            
            if (dailyUsage != null && dailyUsage.containsKey(dateKey)) {
              print('🔍 DEBUG: Found usage for today: ${dailyUsage[dateKey]}');
            } else {
              print('🔍 DEBUG: No usage found for today');
            }
          } else {
            print('🔍 DEBUG: No dailyUsage field in user data');
          }
        }
      } else {
        print('🔍 DEBUG: No user logged in');
      }
    } catch (e) {
      print('🔍 DEBUG: Error in debugUserData: $e');
    }
  }

  // In FirebaseChallengeService class

// Get user notifications
static Stream<List<Map<String, dynamic>>> getUserNotifications() {
  final user = _auth.currentUser;
  if (user == null) return const Stream.empty();

  return _firestore
      .collection('users')
      .doc(user.uid)
      .collection('notifications')
      .orderBy('timestamp', descending: true)
      .snapshots()
      .map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            ...data,
          };
        }).toList();
      });
}

// Mark notification as read
static Future<void> markNotificationAsRead(String notificationId) async {
  final user = _auth.currentUser;
  if (user == null) return;

  await _firestore
      .collection('users')
      .doc(user.uid)
      .collection('notifications')
      .doc(notificationId)
      .update({'isRead': true});
}

  // Force initialize user data (for testing)
  // Add this to your firebase_user_service.dart
static Future<void> forceInitializeUserData() async {
  try {
    final user = _auth.currentUser;
    if (user != null) {
      print('🔄 Force initializing user data...');
      await initializeUserData(
        user.uid, 
        user.email ?? 'user@example.com', 
        user.displayName ?? user.email?.split('@').first ?? 'User'
      );
      print('✅ User data force initialized');
    }
  } catch (e) {
    print('❌ Error force initializing user data: $e');
  }
}
}