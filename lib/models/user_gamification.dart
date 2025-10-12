// models/gamification_user_model.dart
class GamificationUser {
  final String userId;
  final int totalPoints;
  final int completedChallenges;
  final String currentLevel;
  final DateTime? lastActivity;

  GamificationUser({
    required this.userId,
    required this.totalPoints,
    required this.completedChallenges,
    required this.currentLevel,
    this.lastActivity,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'totalPoints': totalPoints,
      'completedChallenges': completedChallenges,
      'currentLevel': currentLevel,
      'lastActivity': lastActivity?.toIso8601String(),
    };
  }

  factory GamificationUser.fromMap(Map<String, dynamic> map) {
    return GamificationUser(
      userId: map['userId'] ?? '',
      totalPoints: map['totalPoints'] ?? 0,
      completedChallenges: map['completedChallenges'] ?? 0,
      currentLevel: map['currentLevel'] ?? 'Beginner',
      lastActivity: map['lastActivity'] != null ? DateTime.parse(map['lastActivity']) : null,
    );
  }
}