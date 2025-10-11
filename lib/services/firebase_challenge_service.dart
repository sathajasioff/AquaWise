import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:watermeter/services/notification_service.dart';

class Challenge {
  final String id;
  final String title;
  final String description;
  final String creatorId;
  final String creatorName;
  final DateTime createdAt;
  final DateTime endDate;
  final int goalLiters;
  final int currentLiters;
  final List<String> participants;
  final List<String> invitedUsers;
  final String reward;
  final bool isPublic;

  Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.creatorId,
    required this.creatorName,
    required this.createdAt,
    required this.endDate,
    required this.goalLiters,
    required this.currentLiters,
    required this.participants,
    required this.invitedUsers,
    required this.reward,
    required this.isPublic,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'creatorId': creatorId,
      'creatorName': creatorName,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'endDate': endDate.millisecondsSinceEpoch,
      'goalLiters': goalLiters,
      'currentLiters': currentLiters,
      'participants': participants,
      'invitedUsers': invitedUsers,
      'reward': reward,
      'isPublic': isPublic,
    };
  }

  static Challenge fromMap(Map<String, dynamic> map) {
    return Challenge(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      creatorId: map['creatorId'],
      creatorName: map['creatorName'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      endDate: DateTime.fromMillisecondsSinceEpoch(map['endDate']),
      goalLiters: map['goalLiters'],
      currentLiters: map['currentLiters'],
      participants: List<String>.from(map['participants']),
      invitedUsers: List<String>.from(map['invitedUsers']),
      reward: map['reward'],
      isPublic: map['isPublic'],
    );
  }

  double get progress => goalLiters > 0 ? currentLiters / goalLiters : 0.0;
  int get participantCount => participants.length;
  bool get isActive => endDate.isAfter(DateTime.now());
}

class FirebaseChallengeService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create a new challenge
  static Future<void> createChallenge({
    required String title,
    required String description,
    required DateTime endDate,
    required int goalLiters,
    required String reward,
    required bool isPublic,
    required List<String> invitedUsers,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userName = userDoc.data()?['name'] ?? 'Unknown User';

      final challengeId = _firestore.collection('challenges').doc().id;
      
      final challenge = Challenge(
        id: challengeId,
        title: title,
        description: description,
        creatorId: user.uid,
        creatorName: userName,
        createdAt: DateTime.now(),
        endDate: endDate,
        goalLiters: goalLiters,
        currentLiters: 0,
        participants: [user.uid], // Creator automatically joins
        invitedUsers: invitedUsers,
        reward: reward,
        isPublic: isPublic,
      );

      await _firestore
          .collection('challenges')
          .doc(challengeId)
          .set(challenge.toMap());

      // Send notifications to invited users
      for (final invitedUserId in invitedUsers) {
        await sendChallengeInvitation(
          challengeId: challengeId,
          challengeTitle: title,
          inviterName: userName,
          invitedUserId: invitedUserId,
        );
      }

    } catch (e) {
      print('Error creating challenge: $e');
      throw e;
    }
  }

  // Send challenge invitation
  static Future<void> sendChallengeInvitation({
    required String challengeId,
    required String challengeTitle,
    required String invitedUserId,
    required String inviterName,
  }) async {
    try {
      await NotificationService.sendChallengeInvitation(
        challengeId: challengeId,
        challengeTitle: challengeTitle,
        inviterName: inviterName,
        invitedUserId: invitedUserId,
      );

      // Also add to invited users list in challenge document
      await _firestore
          .collection('challenges')
          .doc(challengeId)
          .update({
            'invitedUsers': FieldValue.arrayUnion([invitedUserId])
          });

    } catch (e) {
      print('Error sending challenge invitation: $e');
      throw e;
    }
  }

  // Get challenges for current user (created, participating, or public)
  static Stream<List<Challenge>> getUserChallenges() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _firestore
        .collection('challenges')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Challenge.fromMap(doc.data()))
              .where((challenge) =>
                  challenge.participants.contains(user.uid) ||
                  challenge.invitedUsers.contains(user.uid) ||
                  challenge.isPublic ||
                  challenge.creatorId == user.uid)
              .toList();
        });
  }

  // Join a challenge
  static Future<void> joinChallenge(String challengeId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _firestore
          .collection('challenges')
          .doc(challengeId)
          .update({
            'participants': FieldValue.arrayUnion([user.uid])
          });

    } catch (e) {
      print('Error joining challenge: $e');
      throw e;
    }
  }

  // Update challenge progress
  static Future<void> updateChallengeProgress(
    String challengeId, 
    int additionalLiters
  ) async {
    try {
      await _firestore
          .collection('challenges')
          .doc(challengeId)
          .update({
            'currentLiters': FieldValue.increment(additionalLiters)
          });

    } catch (e) {
      print('Error updating challenge progress: $e');
      throw e;
    }
  }

  // Get challenge participants details
  static Stream<List<Map<String, dynamic>>> getChallengeParticipants(String challengeId) {
    return _firestore
        .collection('challenges')
        .doc(challengeId)
        .snapshots()
        .asyncMap((snapshot) async {
          final challenge = Challenge.fromMap(snapshot.data()!);
          final participants = <Map<String, dynamic>>[];

          for (final participantId in challenge.participants) {
            final userDoc = await _firestore.collection('users').doc(participantId).get();
            final userData = userDoc.data();
            
            if (userData != null) {
              participants.add({
                'id': participantId,
                'name': userData['name'] ?? 'Unknown User',
                'avatar': userData['avatar'] ?? '',
                'waterUsage': userData['todayWaterUsage'] ?? 0.0,
              });
            }
          }

          return participants;
        });
  }

  // Get public challenges that user can join
  static Stream<List<Challenge>> getPublicChallenges() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _firestore
        .collection('challenges')
        .where('isPublic', isEqualTo: true)
        .where('endDate', isGreaterThan: DateTime.now().millisecondsSinceEpoch)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Challenge.fromMap(doc.data()))
              .where((challenge) => 
                  !challenge.participants.contains(user.uid) &&
                  !challenge.invitedUsers.contains(user.uid))
              .toList();
        });
  }

  // Get challenges user is invited to
  static Stream<List<Challenge>> getInvitedChallenges() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _firestore
        .collection('challenges')
        .where('invitedUsers', arrayContains: user.uid)
        .where('endDate', isGreaterThan: DateTime.now().millisecondsSinceEpoch)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Challenge.fromMap(doc.data()))
              .where((challenge) => !challenge.participants.contains(user.uid))
              .toList();
        });
  }

  // Join a public challenge
  static Future<void> joinPublicChallenge(String challengeId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _firestore
          .collection('challenges')
          .doc(challengeId)
          .update({
            'participants': FieldValue.arrayUnion([user.uid])
          });

    } catch (e) {
      print('Error joining public challenge: $e');
      throw e;
    }
  }

  // Accept challenge invitation
  static Future<void> acceptChallengeInvitation(String challengeId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _firestore
          .collection('challenges')
          .doc(challengeId)
          .update({
            'participants': FieldValue.arrayUnion([user.uid]),
            'invitedUsers': FieldValue.arrayRemove([user.uid])
          });

    } catch (e) {
      print('Error accepting challenge invitation: $e');
      throw e;
    }
  }

  // Edit a challenge
static Future<void> updateChallenge({
  required String challengeId,
  required String title,
  required String description,
  required DateTime endDate,
  required int goalLiters,
  required String reward,
  required bool isPublic,
}) async {
  try {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Verify user is the creator
    final challengeDoc = await _firestore.collection('challenges').doc(challengeId).get();
    final challenge = Challenge.fromMap(challengeDoc.data()!);
    
    if (challenge.creatorId != user.uid) {
      throw Exception('Only the challenge creator can edit this challenge');
    }

    // Cannot reduce goal if there's already progress
    if (goalLiters < challenge.currentLiters) {
      throw Exception('Cannot reduce goal below current progress of ${challenge.currentLiters}L');
    }

    await _firestore.collection('challenges').doc(challengeId).update({
      'title': title,
      'description': description,
      'endDate': endDate.millisecondsSinceEpoch,
      'goalLiters': goalLiters,
      'reward': reward,
      'isPublic': isPublic,
      'updatedAt': FieldValue.serverTimestamp(),
    });

  } catch (e) {
    print('Error updating challenge: $e');
    throw e;
  }
}

// Delete a challenge
static Future<void> deleteChallenge(String challengeId) async {
  try {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Verify user is the creator and check participants
    final challengeDoc = await _firestore.collection('challenges').doc(challengeId).get();
    final challenge = Challenge.fromMap(challengeDoc.data()!);
    
    if (challenge.creatorId != user.uid) {
      throw Exception('Only the challenge creator can delete this challenge');
    }

    // If there are other participants, archive instead of delete
    if (challenge.participants.length > 1) {
      await _firestore.collection('challenges').doc(challengeId).update({
        'status': 'archived',
        'archivedAt': FieldValue.serverTimestamp(),
      });
      
      // Notify participants
      for (final participantId in challenge.participants) {
        if (participantId != user.uid) {
          await _firestore
              .collection('users')
              .doc(participantId)
              .collection('notifications')
              .add({
                'type': 'challenge_archived',
                'challengeId': challengeId,
                'challengeTitle': challenge.title,
                'creatorName': challenge.creatorName,
                'timestamp': FieldValue.serverTimestamp(),
                'isRead': false,
              });
        }
      }
    } else {
      // No other participants, delete completely
      await _firestore.collection('challenges').doc(challengeId).delete();
    }

  } catch (e) {
    print('Error deleting challenge: $e');
    throw e;
  }
}

// Get challenge by ID
static Future<Challenge> getChallengeById(String challengeId) async {
  try {
    final doc = await _firestore.collection('challenges').doc(challengeId).get();
    if (!doc.exists) {
      throw Exception('Challenge not found');
    }
    return Challenge.fromMap(doc.data()!);
  } catch (e) {
    print('Error getting challenge: $e');
    throw e;
  }
}

  // Get user's friends for invitation
  static Future<List<Map<String, dynamic>>> getUserFriends() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    try {
      // This would depend on your friends system implementation
      // For now, returning empty list - you'll need to implement based on your app's friend system
      return [];
    } catch (e) {
      print('Error getting user friends: $e');
      return [];
    }
  }
}