class UserChallenge {
  final String challengeId;
  final String userId;
  final DateTime startedAt;
  DateTime? completedAt;
  final String status;
  final int earnedPoints;

  UserChallenge({
    required this.challengeId,
    required this.userId,
    required this.startedAt,
    this.completedAt,
    required this.status,
    required this.earnedPoints,
  });

  Map<String, dynamic> toMap() {
    return {
      'challengeId': challengeId,
      'userId': userId,
      'startedAt': startedAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'status': status,
      'earnedPoints': earnedPoints,
    };
  }

  factory UserChallenge.fromMap(Map<String, dynamic> map) {
    return UserChallenge(
      challengeId: map['challengeId'] ?? '',
      userId: map['userId'] ?? '',
      startedAt: DateTime.parse(map['startedAt']),
      completedAt: map['completedAt'] != null ? DateTime.parse(map['completedAt']) : null,
      status: map['status'] ?? 'active',
      earnedPoints: map['earnedPoints'] ?? 0,
    );
  }
}