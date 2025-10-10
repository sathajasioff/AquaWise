class Challenge {
  final String id;
  final String title;
  final String description;
  final int goalLiters;        // e.g., save 500L this week
  final int currentLiters;     // how much the user has saved so far
  final int rewardPoints;      // points awarded when completed
  final bool joined;

  const Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.goalLiters,
    required this.currentLiters,
    required this.rewardPoints,
    this.joined = false,
  });

  double get progress =>
      goalLiters == 0 ? 0 : (currentLiters / goalLiters).clamp(0, 1).toDouble();

  bool get completed => currentLiters >= goalLiters;

  Challenge copyWith({
    String? id,
    String? title,
    String? description,
    int? goalLiters,
    int? currentLiters,
    int? rewardPoints,
    bool? joined,
  }) {
    return Challenge(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      goalLiters: goalLiters ?? this.goalLiters,
      currentLiters: currentLiters ?? this.currentLiters,
      rewardPoints: rewardPoints ?? this.rewardPoints,
      joined: joined ?? this.joined,
    );
  }
}

