import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/usage_model.dart';

class UsageChart extends StatelessWidget {
  final List<WaterUsage> usageLogs;
  const UsageChart({super.key, required this.usageLogs});

  @override
  Widget build(BuildContext context) {
    if (usageLogs.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: Text('No data to display yet', style: TextStyle(color: Colors.grey)),
      );
    }

    // group by day
    final Map<String, double> daily = {};
    for (final u in usageLogs) {
      final k = "${u.date.day}/${u.date.month}";
      daily[k] = (daily[k] ?? 0) + u.liters;
    }
    final keys = daily.keys.toList();
    final spots = List<FlSpot>.generate(keys.length,
        (i) => FlSpot(i.toDouble(), daily[keys[i]]!.toDouble()));

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: true),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 36)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, meta) {
                  final i = v.toInt();
                  if (i >= 0 && i < keys.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(keys[i], style: const TextStyle(fontSize: 10)),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              isCurved: true,
              barWidth: 3,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(show: true, color: Colors.blueAccent.withOpacity(0.15)),
              color: Colors.blueAccent,
              spots: spots,
            ),
          ],
        ),
      ),
    );
  }
}
