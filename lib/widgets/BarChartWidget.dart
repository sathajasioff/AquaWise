// widgets/bar_chart_widget.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class DailyUsageBarChart extends StatelessWidget {
  final Map<String, double> dailyUsage;

  const DailyUsageBarChart({super.key, required this.dailyUsage});

  @override
  Widget build(BuildContext context) {
    if (dailyUsage.isEmpty) {
      return const Center(
        child: Text('No data available for chart'),
      );
    }

    return SizedBox(
      height: 300,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: _getMaxY(),
          barGroups: _buildBarGroups(),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  final keys = dailyUsage.keys.toList();
                  if (index >= 0 && index < keys.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        keys[index],
                        style: const TextStyle(fontSize: 10),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text('${value.toInt()}L');
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  double _getMaxY() {
    final maxValue = dailyUsage.values.reduce((a, b) => a > b ? a : b);
    return maxValue + 10;
  }

  List<BarChartGroupData> _buildBarGroups() {
    final keys = dailyUsage.keys.toList();
    return List.generate(dailyUsage.length, (index) {
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: dailyUsage[keys[index]] ?? 0,
            color: Colors.blue,
            width: 16,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    });
  }
}