// models/water_usage_model.dart
class WaterUsage {
  final String id;
  final String userId;
  final String activity;
  final double litersUsed;
  final DateTime timestamp;
  final String? deviceId;
  final String? location;
  final Duration? duration;
  final double? cost;

  WaterUsage({
    required this.id,
    required this.userId,
    required this.activity,
    required this.litersUsed,
    required this.timestamp,
    this.deviceId,
    this.location,
    this.duration,
    this.cost,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'activity': activity,
      'litersUsed': litersUsed,
      'timestamp': timestamp.toIso8601String(),
      'deviceId': deviceId,
      'location': location,
      'duration': duration?.inSeconds,
      'cost': cost,
    };
  }

  factory WaterUsage.fromMap(Map<String, dynamic> map) {
    return WaterUsage(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      activity: map['activity'] ?? '',
      litersUsed: (map['litersUsed'] ?? 0).toDouble(),
      timestamp: DateTime.parse(map['timestamp']),
      deviceId: map['deviceId'],
      location: map['location'],
      duration: map['duration'] != null ? Duration(seconds: map['duration']) : null,
      cost: map['cost']?.toDouble(),
    );
  }
}