// lib/features/ai_tips/model/ai_tip_model.dart
class AiTip {
  final String id;
  final String category;
  final String description;
  final int estimatedSaveLitres;
  final String source; // "AI" or "Community" or "Manual"

  AiTip({
    required this.id,
    required this.category,
    required this.description,
    required this.estimatedSaveLitres,
    required this.source,
  });

  factory AiTip.fromMap(Map<String, dynamic> data, String id) {
    return AiTip(
      id: id,
      category: data['category'] ?? 'General',
      description: data['description'] ?? '',
      estimatedSaveLitres: data['estimatedSaveLitres'] ?? 0,
      source: data['source'] ?? 'Community',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'category': category,
      'description': description,
      'estimatedSaveLitres': estimatedSaveLitres,
      'source': source,
    };
  }
}
