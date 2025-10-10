// models/badge_model.dart
class Badge {
  final String id;
  final String name;
  final String description;
  final String icon; // Icon name or URL
  final int pointsRequired;
  final String category; // 'water_saver', 'eco_warrior', 'budget_master', etc.
  final String rarity; // 'common', 'rare', 'epic', 'legendary'

  Badge({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.pointsRequired,
    required this.category,
    required this.rarity,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'pointsRequired': pointsRequired,
      'category': category,
      'rarity': rarity,
    };
  }

  factory Badge.fromMap(Map<String, dynamic> map) {
    return Badge(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      icon: map['icon'] ?? '🏆',
      pointsRequired: map['pointsRequired'] ?? 0,
      category: map['category'] ?? 'general',
      rarity: map['rarity'] ?? 'common',
    );
  }
}

class UserBadge {
  final String badgeId;
  final String userId;
  final DateTime earnedAt;
  final int pointsWhenEarned;

  UserBadge({
    required this.badgeId,
    required this.userId,
    required this.earnedAt,
    required this.pointsWhenEarned,
  });

  Map<String, dynamic> toMap() {
    return {
      'badgeId': badgeId,
      'userId': userId,
      'earnedAt': earnedAt.toIso8601String(),
      'pointsWhenEarned': pointsWhenEarned,
    };
  }

  factory UserBadge.fromMap(Map<String, dynamic> map) {
    return UserBadge(
      badgeId: map['badgeId'] ?? '',
      userId: map['userId'] ?? '',
      earnedAt: DateTime.parse(map['earnedAt']),
      pointsWhenEarned: map['pointsWhenEarned'] ?? 0,
    );
  }
}