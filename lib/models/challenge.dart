class Challenge {
  final String id;
  final String title;
  final String description;
  final int points;
  final String type;
  final String activity;
  final int targetTime;
  final double targetLiters;
  final String difficulty;

  Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.points,
    required this.type,
    required this.activity,
    required this.targetTime,
    required this.targetLiters,
    required this.difficulty,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'points': points,
      'type': type,
      'activity': activity,
      'targetTime': targetTime,
      'targetLiters': targetLiters,
      'difficulty': difficulty,
    };
  }

  factory Challenge.fromMap(Map<String, dynamic> map) {
    return Challenge(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      points: map['points'] ?? 0,
      type: map['type'] ?? 'casual',
      activity: map['activity'] ?? '',
      targetTime: map['targetTime'] ?? 0,
      targetLiters: (map['targetLiters'] ?? 0.0).toDouble(),
      difficulty: map['difficulty'] ?? 'easy',
    );
  }
}