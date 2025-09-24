class LeaderboardEntry {
  final int rank;
  final String name;
  final int points;
  final bool isYou;

  const LeaderboardEntry({
    required this.rank,
    required this.name,
    required this.points,
    this.isYou = false,
  });
}
