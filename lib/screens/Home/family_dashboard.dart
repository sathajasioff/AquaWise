import 'package:flutter/material.dart';
import '../../controllers/dashboard_controller.dart';

class FamilyDashboard extends StatelessWidget {
  final DashboardController controller;
  const FamilyDashboard({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("👨‍👩‍👧 Family Dashboard", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        StreamBuilder<Map<String, double>>(
          stream: controller.familyBreakdownThisMonth(),
          builder: (context, snap) {
            final map = snap.data ?? {};
            if (map.isEmpty) return const Text("No family usage yet.");

            final items = map.entries.toList()..sort((a,b)=>b.value.compareTo(a.value));
            return Column(
              children: items.map((e) => Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(e.key),
                  trailing: Text("${e.value.toStringAsFixed(1)} L"),
                ),
              )).toList(),
            );
          },
        ),
        const SizedBox(height: 8),
        const _Hint("Tip: You can add memberName to logs to see per-person usage."),
      ],
    );
  }
}

class _Hint extends StatelessWidget {
  final String text;
  const _Hint(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Text(text, style: const TextStyle(color: Colors.grey)),
  );
}
