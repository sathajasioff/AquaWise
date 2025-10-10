class UserChallenge {
  final String id;
  final String challengeId;
  final String userId;
  final String status; // 'active', 'completed', 'failed'
  final DateTime startedAt;
  final DateTime? completedAt;
  final DateTime? failedAt;
  final int pointsEarned;

  UserChallenge({
    required this.id,
    required this.challengeId,
    required this.userId,
    required this.status,
    required this.startedAt,
    this.completedAt,
    this.failedAt,
    this.pointsEarned = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'challengeId': challengeId,
      'userId': userId,
      'status': status,
      'startedAt': startedAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'failedAt': failedAt?.toIso8601String(),
      'pointsEarned': pointsEarned,
    };
  }

  static UserChallenge fromMap(String id, Map<String, dynamic> map) {
    return UserChallenge(
      id: id,
      challengeId: map['challengeId'] as String,
      userId: map['userId'] as String,
      status: map['status'] as String,
      startedAt: DateTime.parse(map['startedAt'] as String),
      completedAt: map['completedAt'] != null ? DateTime.parse(map['completedAt'] as String) : null,
      failedAt: map['failedAt'] != null ? DateTime.parse(map['failedAt'] as String) : null,
      pointsEarned: (map['pointsEarned'] as int?) ?? 0,
    );
  }
}