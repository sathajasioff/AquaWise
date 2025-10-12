// class WaterUsage {
//   final String id;
//   final String activity;
//   final double liters;
//   final DateTime date;

//   WaterUsage({
//     required this.id,
//     required this.activity,
//     required this.liters,
//     required this.date,
//   });

//   Map<String, dynamic> toMap() {
//     return {
//       'activity': activity,
//       'liters': liters,
//       'date': date.toIso8601String(),
//     };
//   }

//   factory WaterUsage.fromMap(String id, Map<String, dynamic> data) {
//     return WaterUsage(
//       id: id,
//       activity: data['activity'] ?? '',
//       liters: (data['liters'] ?? 0).toDouble(),
//       date: DateTime.parse(data['date']),
//     );
//   }
  

//   get memberName => null;
// }
import 'package:cloud_firestore/cloud_firestore.dart';

class WaterUsage {
  final String id;
  final String activity;
  final double liters;
  final DateTime date;

  WaterUsage({
    required this.id,
    required this.activity,
    required this.liters,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'activity': activity,
      'liters': liters,
      'date': date.toIso8601String(),
    };
  }

  factory WaterUsage.fromMap(String id, Map<String, dynamic> data) {
    return WaterUsage(
      id: id,
      activity: data['activity'] ?? '',
      liters: (data['liters'] ?? 0).toDouble(),
      date: data['date'] is Timestamp
          ? (data['date'] as Timestamp).toDate()
          : DateTime.parse(data['date']),
    );
  }

  get memberName => null;
}
