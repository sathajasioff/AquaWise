// widgets/pie_chart_widget.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class WaterUsagePieChart extends StatelessWidget {
  final Map<String, double> usageByActivity;

  const WaterUsagePieChart({super.key, required this.usageByActivity});

  @override
  Widget build(BuildContext context) {
    if (usageByActivity.isEmpty) {
      return const Center(
        child: Text('No data available for chart'),
      );
    }

    return SizedBox(
      height: 300,
      child: PieChart(
        PieChartData(
          sections: _buildSections(),
          centerSpaceRadius: 40,
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildSections() {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.amber,
      Colors.cyan,
    ];

    final total = usageByActivity.values.reduce((a, b) => a + b);
    int colorIndex = 0;

    return usageByActivity.entries.map((entry) {
      final percentage = (entry.value / total * 100).toStringAsFixed(1);
      final color = colors[colorIndex % colors.length];
      colorIndex++;

      return PieChartSectionData(
        color: color,
        value: entry.value,
        title: '${percentage}%',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }
}