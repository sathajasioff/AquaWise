import 'package:flutter/material.dart';
import '../../controllers/dashboard_controller.dart';

class EcoDashboard extends StatelessWidget {
  final DashboardController controller;
  const EcoDashboard({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, double>>(
      future: controller.thisVsLastWeek(),
      builder: (context, snap) {
        final thisW = (snap.data?['this'] ?? 0);
        final lastW = (snap.data?['last'] ?? 0);
        final diff = lastW - thisW; // positive = saved
        final pct = lastW > 0 ? (diff / lastW * 100) : 0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("🌱 Eco Dashboard", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _metricCard("Usage vs last week", "${pct.toStringAsFixed(1)}%", subtitle: "Saved ${(diff).toStringAsFixed(1)} L"),
            const SizedBox(height: 8),
            const _Badge(text: "Low-flow Hero"),
            const _Badge(text: "Shower Saver"),
          ],
        );
      },
    );
  }

  Widget _metricCard(String title, String value, {String? subtitle}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const Icon(Icons.eco, color: Colors.green),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: subtitle != null ? Text(subtitle) : null,
        trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}

extension on DashboardController {
  Future<Map<String, double>>? thisVsLastWeek() {}
}

class _Badge extends StatelessWidget {
  final String text;
  const _Badge({required this.text});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.12),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(text, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
    );
  }
}
