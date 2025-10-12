// models/report_data_model.dart
import 'package:watermeter/models/usage_model.dart';
import 'package:watermeter/models/water_bill_model.dart';

class ReportData {
  final DateTime periodStart;
  final DateTime periodEnd;
  final double totalLiters;
  final double totalCost;
  final Map<String, double> usageByActivity;
  final Map<String, double> dailyUsage;
  final Map<String, double> weeklyUsage;
  final List<WaterUsage> usageRecords;
  final WaterBill? currentBill;

  ReportData({
    required this.periodStart,
    required this.periodEnd,
    required this.totalLiters,
    required this.totalCost,
    required this.usageByActivity,
    required this.dailyUsage,
    required this.weeklyUsage,
    required this.usageRecords,
    this.currentBill,
  });

  double get averageDailyUsage {
    final days = periodEnd.difference(periodStart).inDays;
    return days > 0 ? totalLiters / days : 0;
  }

  String get mostUsedActivity {
    if (usageByActivity.isEmpty) return 'No data';
    final entry = usageByActivity.entries.reduce((a, b) => a.value > b.value ? a : b);
    return entry.key;
  }
}