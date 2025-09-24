class Reward {
  final String id;
  final String title;
  final String description;
  final int costPoints;      // points required to redeem
  final String? image;       // optional network/local asset

  const Reward({
    required this.id,
    required this.title,
    required this.description,
    required this.costPoints,
    this.image,
  });
}
