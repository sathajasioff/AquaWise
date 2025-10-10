// controllers/gamification_controller.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_challenge.dart';
import '../../models/challenge.dart' hide UserChallenge;
import '../../models/user_gamification.dart';
import '../models/badge.dart';

class GamificationController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ✅ Predefined challenges for each persona (userType)
  final List<Challenge> _allChallenges = [
    // 🌱 Eco Warrior
    Challenge(
      id: 'eco_1',
      title: '5-Minute Shower',
      description: 'Complete your shower within 5 minutes to save water',
      points: 50,
      type: 'eco',
      activity: 'Bathing',
      targetTime: 300,
      targetLiters: 50.0,
      difficulty: 'easy',
    ),
    Challenge(
      id: 'eco_2',
      title: 'Bucket Bath Challenge',
      description: 'Use only one bucket of water for bathing',
      points: 100,
      type: 'eco',
      activity: 'Bathing',
      targetTime: 600,
      targetLiters: 20.0,
      difficulty: 'medium',
    ),
    Challenge(
      id: 'eco_3',
      title: 'Zero Waste Cooking',
      description: 'Cook without wasting any water',
      points: 75,
      type: 'eco',
      activity: 'Cooking',
      targetTime: 1800,
      targetLiters: 10.0,
      difficulty: 'medium',
    ),

    // 💰 Budget Saver
    Challenge(
      id: 'budget_1',
      title: 'Weekly Budget Keeper',
      description: 'Stay within your weekly water budget',
      points: 150,
      type: 'budget',
      activity: 'All',
      targetTime: 604800,
      targetLiters: 1250.0,
      difficulty: 'hard',
    ),
    Challenge(
      id: 'budget_2',
      title: 'Smart Dish Washing',
      description: 'Wash dishes using less than 15 liters',
      points: 60,
      type: 'budget',
      activity: 'Cleaning',
      targetTime: 900,
      targetLiters: 15.0,
      difficulty: 'easy',
    ),

    // 👨‍👩‍👧 Family Manager
    Challenge(
      id: 'family_1',
      title: 'Family Shower Time',
      description: 'Coordinate family showers to save water',
      points: 120,
      type: 'family',
      activity: 'Bathing',
      targetTime: 1800,
      targetLiters: 200.0,
      difficulty: 'medium',
    ),

    // 🙂 Casual User
    Challenge(
      id: 'casual_1',
      title: 'Quick Brush',
      description: 'Turn off tap while brushing teeth',
      points: 30,
      type: 'casual',
      activity: 'Personal',
      targetTime: 180,
      targetLiters: 5.0,
      difficulty: 'easy',
    ),
  ];

  // 🏆 Predefined badges - UNIVERSAL FOR ALL USER TYPES
  final List<Badge> _allBadges = [
    // 🌱 Beginner Badges - Available to ALL users
    Badge(
      id: 'beginner_saver',
      name: 'Water Saver Beginner',
      description: 'Save your first 100 liters of water',
      icon: '💧',
      pointsRequired: 100,
      category: 'water_saver',
      rarity: 'common',
    ),
    Badge(
      id: 'first_challenge',
      name: 'First Challenge Complete',
      description: 'Complete your first water saving challenge',
      icon: '🎯',
      pointsRequired: 50,
      category: 'achiever',
      rarity: 'common',
    ),

    // 💰 Budget Badges - Available to ALL users
    Badge(
      id: 'budget_master',
      name: 'Budget Master',
      description: 'Stay within budget for 4 consecutive weeks',
      icon: '💰',
      pointsRequired: 500,
      category: 'budget',
      rarity: 'rare',
    ),
    Badge(
      id: 'smart_spender',
      name: 'Smart Spender',
      description: 'Save 20% on your water bill for a month',
      icon: '📊',
      pointsRequired: 300,
      category: 'budget',
      rarity: 'rare',
    ),

    // 🌿 Eco Warrior Badges - Available to ALL users
    Badge(
      id: 'eco_warrior',
      name: 'Eco Warrior',
      description: 'Complete 10 eco-friendly challenges',
      icon: '🌿',
      pointsRequired: 800,
      category: 'eco',
      rarity: 'epic',
    ),
    Badge(
      id: 'planet_protector',
      name: 'Planet Protector',
      description: 'Save over 1000 liters of water',
      icon: '🌎',
      pointsRequired: 1000,
      category: 'eco',
      rarity: 'epic',
    ),

    // 👨‍👩‍👧 Family Badges - Available to ALL users
    Badge(
      id: 'family_hero',
      name: 'Family Water Hero',
      description: 'Get your whole family to save water together',
      icon: '👨‍👩‍👧‍👦',
      pointsRequired: 600,
      category: 'family',
      rarity: 'rare',
    ),

    // 🏆 Advanced Badges - Available to ALL users
    Badge(
      id: 'water_wizard',
      name: 'Water Wizard',
      description: 'Master all types of water saving challenges',
      icon: '🧙‍♂️',
      pointsRequired: 1500,
      category: 'master',
      rarity: 'legendary',
    ),
    Badge(
      id: 'conservation_champion',
      name: 'Conservation Champion',
      description: 'Save over 5000 liters of water',
      icon: '🏆',
      pointsRequired: 5000,
      category: 'master',
      rarity: 'legendary',
    ),
  ];

  // ✅ Return challenges filtered by userType
  List<Challenge> getChallengesForPersona(String userType) {
    final cleanType = userType.trim().toLowerCase();
    print('🎯 Filtering challenges for userType: "$cleanType"');

    if (cleanType.contains('eco') || cleanType.contains('environment') || cleanType.contains('green')) {
      final ecoChallenges = _allChallenges.where((c) => c.type == 'eco').toList();
      print('🌱 Found ${ecoChallenges.length} eco challenges');
      return ecoChallenges;
    } 
    else if (cleanType.contains('budget') || cleanType.contains('money') || cleanType.contains('save') || cleanType.contains('saver')) {
      final budgetChallenges = _allChallenges.where((c) => c.type == 'budget').toList();
      print('💰 Found ${budgetChallenges.length} budget challenges');
      return budgetChallenges;
    } 
    else if (cleanType.contains('family') || cleanType.contains('parent') || cleanType.contains('household')) {
      final familyChallenges = _allChallenges.where((c) => c.type == 'family').toList();
      print('👨‍👩‍👧 Found ${familyChallenges.length} family challenges');
      return familyChallenges;
    } 
    else {
      final casualChallenges = _allChallenges.where((c) => c.type == 'casual').toList();
      print('🙂 Found ${casualChallenges.length} casual challenges');
      return casualChallenges;
    }
  }

  // ✅ Get userType from Firestore
  Future<String> getUserPersona() async {
    final user = _auth.currentUser;
    if (user == null) return 'casual';

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        final userType = data['userType'] ?? data['UserType'] ?? data['usertype'] ?? data['persona'] ?? 'casual';
        return userType.toString().toLowerCase().trim();
      }
      return 'casual';
    } catch (e) {
      print('❌ Error fetching userType: $e');
      return 'casual';
    }
  }

  // ✅ NEW: Get essential user data in single read
  Future<Map<String, dynamic>> getUserEssentialData() async {
    final user = _auth.currentUser;
    if (user == null) return {'userType': 'casual', 'username': 'User'};

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      
      if (!userDoc.exists) {
        return {'userType': 'casual', 'username': 'User'};
      }

      final userData = userDoc.data()!;
      final dynamic userTypeValue = userData['userType'] ?? 
                                  userData['UserType'] ?? 
                                  userData['usertype'] ?? 
                                  userData['persona'] ?? 
                                  'casual';
      
      final String userType = userTypeValue.toString().toLowerCase().trim();
      
      return {
        'userType': userType,
        'username': userData['username'] ?? 'User',
        'email': userData['email'] ?? '',
      };
      
    } catch (e) {
      print('❌ Error loading essential data: $e');
      return {'userType': 'casual', 'username': 'User'};
    }
  }

  // ✅ Start a new challenge - FOR ALL USER TYPES
  Future<void> startChallenge(Challenge challenge) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final userChallenge = UserChallenge(
        challengeId: challenge.id,
        userId: user.uid,
        startedAt: DateTime.now(),
        status: 'active',
        earnedPoints: 0,
      );

      final docId = '${user.uid}_${challenge.id}_${DateTime.now().millisecondsSinceEpoch}';
      
      await _firestore
          .collection('userChallenges')
          .doc(docId)
          .set(userChallenge.toMap());

      print('🎯 Started challenge: ${challenge.title} for user ${user.uid}');
    } catch (e) {
      print('❌ Error starting challenge: $e');
      rethrow;
    }
  }

  // ✅ Complete a challenge - FOR ALL USER TYPES
  Future<void> completeChallenge(String challengeId, int actualTime, double actualLiters) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final query = await _firestore
          .collection('userChallenges')
          .where('userId', isEqualTo: user.uid)
          .where('challengeId', isEqualTo: challengeId)
          .where('status', isEqualTo: 'active')
          .get();

      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        final challenge = _allChallenges.firstWhere((c) => c.id == challengeId);

        bool success = true;
        if (challenge.targetTime > 0 && actualTime > challenge.targetTime) success = false;
        if (challenge.targetLiters > 0 && actualLiters > challenge.targetLiters) success = false;

        await doc.reference.update({
          'status': success ? 'completed' : 'failed',
          'completedAt': DateTime.now().toIso8601String(),
          'earnedPoints': success ? challenge.points : 0,
        });

        print('${success ? '✅' : '❌'} Challenge ${challenge.title} ${success ? 'completed' : 'failed'}');

        if (success) {
          await _updateUserPoints(challenge.points);
        }
      } else {
        print('⚠️ No active challenge found with ID: $challengeId');
      }
    } catch (e) {
      print('❌ Error completing challenge: $e');
    }
  }

  // ✅ Update total points with badge checking - ENHANCED FOR ALL USERS
  Future<void> _updateUserPoints(int points) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final userDoc = _firestore.collection('gamificationUsers').doc(user.uid);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(userDoc);

        int newTotalPoints;
        int completedChallenges;

        if (snapshot.exists) {
          final currentPoints = snapshot.data()?['totalPoints'] ?? 0;
          completedChallenges = snapshot.data()?['completedChallenges'] ?? 0;
          newTotalPoints = currentPoints + points;

          transaction.update(userDoc, {
            'totalPoints': newTotalPoints,
            'completedChallenges': completedChallenges + 1,
            'lastActivity': DateTime.now().toIso8601String(),
          });
          
          print('💰 Updated points: $currentPoints + $points = $newTotalPoints');
        } else {
          newTotalPoints = points;
          completedChallenges = 1;
          final gamificationUser = GamificationUser(
            userId: user.uid,
            totalPoints: points,
            completedChallenges: 1,
            currentLevel: 'Beginner',
            lastActivity: DateTime.now(),
          );
          transaction.set(userDoc, gamificationUser.toMap());
          print('🆕 Created new gamification user with $points points');
        }

        // Check for new badges after points update
        print('🔍 Checking for badges at $newTotalPoints points...');
        await _checkAndAwardBadges(newTotalPoints);
      });
    } catch (e) {
      print('❌ Error updating user points: $e');
    }
  }

  // 🏆 Check and award badges when points are updated - FIXED FOR ALL USER TYPES
  Future<void> _checkAndAwardBadges(int newTotalPoints) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // Get current user badges
      final userBadgesSnapshot = await _firestore
          .collection('userBadges')
          .where('userId', isEqualTo: user.uid)
          .get();

      final earnedBadgeIds = userBadgesSnapshot.docs.map((doc) => doc.data()['badgeId'] as String).toSet();

      // Find ALL badges that user qualifies for but hasn't earned yet
      final eligibleBadges = _allBadges.where((badge) {
        final qualifies = newTotalPoints >= badge.pointsRequired;
        final notEarned = !earnedBadgeIds.contains(badge.id);
        
        if (qualifies && notEarned) {
          print('🎯 Eligible badge: ${badge.name} (${badge.pointsRequired} points)');
        }
        
        return qualifies && notEarned;
      }).toList();

      print('🎯 Total eligible badges: ${eligibleBadges.length} at $newTotalPoints points');
      print('📊 Earned badges: ${earnedBadgeIds.length}, Total badges: ${_allBadges.length}');

      // Award ALL eligible badges at once
      for (final badge in eligibleBadges) {
        await _awardBadge(badge, newTotalPoints);
        print('✅ Awarded badge: ${badge.name} (${badge.pointsRequired} points)');
      }

      // If we awarded any badges, print summary
      if (eligibleBadges.isNotEmpty) {
        print('🎉 Successfully awarded ${eligibleBadges.length} badges!');
        print('📈 New total points: $newTotalPoints');
      } else {
        print('ℹ️ No new badges to award at $newTotalPoints points');
      }
      
    } catch (e) {
      print('❌ Error checking badges: $e');
    }
  }

  // 🏆 Award a specific badge to user
  Future<void> _awardBadge(Badge badge, int currentPoints) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final userBadge = UserBadge(
        badgeId: badge.id,
        userId: user.uid,
        earnedAt: DateTime.now(),
        pointsWhenEarned: currentPoints,
      );

      await _firestore
          .collection('userBadges')
          .doc('${user.uid}_${badge.id}')
          .set(userBadge.toMap());

      print('🎖️ Successfully awarded badge: ${badge.name}');
    } catch (e) {
      print('❌ Error awarding badge: $e');
    }
  }

  // 🏆 Get user's earned badges
  Stream<List<UserBadge>> _getUserBadges() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _firestore
        .collection('userBadges')
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserBadge.fromMap(doc.data()))
            .toList());
  }

  // 🏆 Get user badges with badge details
  Stream<List<Map<String, dynamic>>> getUserBadgesWithDetails() {
    return _getUserBadges().map((userBadges) {
      return userBadges.map((userBadge) {
        final badge = _allBadges.firstWhere(
          (b) => b.id == userBadge.badgeId,
          orElse: () => Badge(
            id: userBadge.badgeId,
            name: 'Unknown Badge',
            description: 'Badge details not available',
            icon: '🏆',
            pointsRequired: 0,
            category: 'general',
            rarity: 'common',
          ),
        );
        return {
          'badge': badge,
          'userBadge': userBadge,
          'earned': true,
        };
      }).toList();
    });
  }

  // 🏆 Get available badges (not yet earned)
  Stream<List<Badge>> getAvailableBadges() {
    return _getUserBadges().map((userBadges) {
      final earnedBadgeIds = userBadges.map((b) => b.badgeId).toSet();
      return _allBadges.where((badge) => !earnedBadgeIds.contains(badge.id)).toList();
    });
  }

  // 🏆 Get user's next achievable badges
  Stream<List<Badge>> getNextBadges() {
    return getUserPoints().map((currentPoints) {
      return _allBadges
          .where((badge) => badge.pointsRequired > currentPoints)
          .toList()
        ..sort((a, b) => a.pointsRequired.compareTo(b.pointsRequired))
        ..take(3);
    });
  }

  // 🏆 Get user progress towards next badge - FIXED FOR ALL USER TYPES
  Stream<Map<String, dynamic>> getBadgeProgress() {
    return getUserPoints().asyncMap((currentPoints) async {
      final userBadges = await _getUserBadges().first;
      final earnedBadgeIds = userBadges.map((b) => b.badgeId).toSet();

      // Find badges that user hasn't earned yet
      final unearnedBadges = _allBadges
          .where((badge) => !earnedBadgeIds.contains(badge.id))
          .toList();

      if (unearnedBadges.isNotEmpty) {
        // Sort by points required to get the progression order
        unearnedBadges.sort((a, b) => a.pointsRequired.compareTo(b.pointsRequired));
        
        // Always take the first unearned badge (lowest points requirement)
        final nextBadge = unearnedBadges.first;
        
        // Calculate progress and points needed
        final progress = (currentPoints / nextBadge.pointsRequired).clamp(0.0, 1.0);
        final pointsNeeded = (nextBadge.pointsRequired - currentPoints).clamp(0, nextBadge.pointsRequired);
        final isAchievable = currentPoints >= nextBadge.pointsRequired;
        
        // Debug information
        print('🎯 Badge Progress for all users:');
        print('   - Current Points: $currentPoints');
        print('   - Next Badge: ${nextBadge.name} (${nextBadge.pointsRequired} points)');
        print('   - Points Needed: $pointsNeeded');
        print('   - Is Achievable: $isAchievable');
        print('   - Unearned Badges: ${unearnedBadges.length}');
        print('   - Earned Badges: ${earnedBadgeIds.length}');
        
        return {
          'nextBadge': nextBadge,
          'currentPoints': currentPoints,
          'pointsRequired': nextBadge.pointsRequired,
          'progress': progress,
          'pointsNeeded': pointsNeeded,
          'isAchievable': isAchievable,
          'status': isAchievable ? 'Ready to Earn!' : 'In Progress',
          'unearnedBadgesCount': unearnedBadges.length,
        };
      }
      
      // All badges earned
      print('🏆 All badges earned! Total points: $currentPoints');
      return {
        'nextBadge': null,
        'currentPoints': currentPoints,
        'pointsRequired': 0,
        'progress': 1.0,
        'pointsNeeded': 0,
        'isAchievable': false,
        'status': 'All Badges Earned! 🎉',
        'unearnedBadgesCount': 0,
      };
    });
  }

  // ✅ Streams for ALL USER TYPES
  Stream<List<UserChallenge>> getActiveChallenges() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _firestore
        .collection('userChallenges')
        .where('userId', isEqualTo: user.uid)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) {
          final challenges = snapshot.docs.map((doc) => UserChallenge.fromMap(doc.data())).toList();
          return challenges;
        });
  }

  Stream<List<UserChallenge>> getCompletedChallenges() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _firestore
        .collection('userChallenges')
        .where('userId', isEqualTo: user.uid)
        .where('status', isEqualTo: 'completed')
        .snapshots()
        .map((snapshot) {
          final challenges = snapshot.docs.map((doc) => UserChallenge.fromMap(doc.data())).toList();
          return challenges;
        });
  }

  Stream<int> getUserPoints() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(0);

    return _firestore
        .collection('gamificationUsers')
        .doc(user.uid)
        .snapshots()
        .map((snap) {
          if (!snap.exists) return 0;
          final data = snap.data();
          if (data == null) return 0;
          final points = (data['totalPoints'] ?? 0) as int;
          return points;
        });
  }

  // 🎯 CASUAL TASKS METHODS - Only for casual users
  Stream<List<Map<String, dynamic>>> getCasualTasksFromLeaderboard() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _firestore
        .collection('leaderboard')
        .doc(user.uid)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists) return <Map<String, dynamic>>[];

          final data = snapshot.data()!;
          final userTasks = data['userTasks'] as Map<String, dynamic>?;
          
          if (userTasks == null || userTasks.isEmpty) {
            return <Map<String, dynamic>>[];
          }

          return userTasks.entries.map((entry) {
            final taskData = entry.value as Map<String, dynamic>;
            return {
              'taskId': entry.key,
              'taskName': taskData['taskName'] ?? 'Unknown Task',
              'status': taskData['status'] ?? 'started',
              'startedAt': taskData['startedAt'],
              'completedAt': taskData['completedAt'],
              'pointsEarned': taskData['pointsEarned'] ?? 0,
              'category': taskData['category'] ?? 'general',
              'isFromLeaderboard': true,
            };
          }).toList();
        }).handleError((error) {
          print('❌ Error in casual tasks stream: $error');
          return <Map<String, dynamic>>[];
        });
  }

  // 🎯 COMPLETE CASUAL TASK - Only for casual users
  Future<void> completeCasualTaskFromGamification(String taskId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user logged in');

    try {
      final leaderboardRef = _firestore.collection('leaderboard').doc(user.uid);
      
      await _firestore.runTransaction((transaction) async {
        final leaderboardDoc = await transaction.get(leaderboardRef);
        
        if (!leaderboardDoc.exists) {
          throw Exception('No leaderboard entry found for user');
        }

        final data = leaderboardDoc.data()!;
        final userTasks = data['userTasks'] as Map<String, dynamic>? ?? {};
        
        if (!userTasks.containsKey(taskId)) {
          throw Exception('Task $taskId not found in user tasks');
        }

        final taskData = userTasks[taskId] as Map<String, dynamic>;
        final currentStatus = taskData['status'] ?? 'started';
        
        if (currentStatus == 'completed') {
          throw Exception('Task is already completed');
        }

        final int points = _calculateTaskPoints(taskData);
        final currentTotalPoints = (data['totalPoints'] ?? 0) as int;
        
        print('🎯 Completing casual task $taskId with $points points');

        transaction.update(leaderboardRef, {
          'userTasks.$taskId.status': 'completed',
          'userTasks.$taskId.completedAt': DateTime.now().toIso8601String(),
          'userTasks.$taskId.pointsEarned': points,
          'totalPoints': currentTotalPoints + points,
          'lastUpdated': DateTime.now().toIso8601String(),
        });
      });

      // Update gamification system
      final leaderboardDoc = await leaderboardRef.get();
      final data = leaderboardDoc.data()!;
      final userTasks = data['userTasks'] as Map<String, dynamic>? ?? {};
      final taskData = userTasks[taskId] as Map<String, dynamic>;
      final points = _calculateTaskPoints(taskData);
      
      await _updateUserPoints(points);
      
      print('✅ Successfully completed casual task: $taskId');
      
    } catch (e) {
      print('❌ Error completing casual task: $e');
      rethrow;
    }
  }

  // 🎯 CALCULATE TASK POINTS
  int _calculateTaskPoints(Map<String, dynamic> taskData) {
    final String taskName = taskData['taskName']?.toString().toLowerCase() ?? '';
    final String category = taskData['category']?.toString().toLowerCase() ?? 'general';
    
    if (category.contains('daily')) return 25;
    if (category.contains('weekly')) return 50;
    if (category.contains('achievement')) return 100;
    if (taskName.contains('challenge')) return 75;
    if (taskName.contains('water') && taskName.contains('save')) return 60;
    
    return 30;
  }

  Stream<GamificationUser?> getGamificationUser() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(null);

    return _firestore
        .collection('gamificationUsers')
        .doc(user.uid)
        .snapshots()
        .map((snap) => snap.exists ? GamificationUser.fromMap(snap.data()!) : null);
  }
}