// models/water_bill_model.dart
class WaterBill {
  final String id;
  final String userId;
  final DateTime periodStart;
  final DateTime periodEnd;
  final double totalLiters;
  final double totalCost;
  final double ratePerLiter;
  final Map<String, double> usageByActivity;
  final DateTime? paidAt;
  final String status;

  WaterBill({
    required this.id,
    required this.userId,
    required this.periodStart,
    required this.periodEnd,
    required this.totalLiters,
    required this.totalCost,
    required this.ratePerLiter,
    required this.usageByActivity,
    this.paidAt,
    this.status = 'pending',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'periodStart': periodStart.toIso8601String(),
      'periodEnd': periodEnd.toIso8601String(),
      'totalLiters': totalLiters,
      'totalCost': totalCost,
      'ratePerLiter': ratePerLiter,
      'usageByActivity': usageByActivity,
      'paidAt': paidAt?.toIso8601String(),
      'status': status,
    };
  }

  factory WaterBill.fromMap(Map<String, dynamic> map) {
    return WaterBill(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      periodStart: DateTime.parse(map['periodStart']),
      periodEnd: DateTime.parse(map['periodEnd']),
      totalLiters: (map['totalLiters'] ?? 0).toDouble(),
      totalCost: (map['totalCost'] ?? 0).toDouble(),
      ratePerLiter: (map['ratePerLiter'] ?? 0).toDouble(),
      usageByActivity: Map<String, double>.from(map['usageByActivity'] ?? {}),
      paidAt: map['paidAt'] != null ? DateTime.parse(map['paidAt']) : null,
      status: map['status'] ?? 'pending',
    );
  }
}