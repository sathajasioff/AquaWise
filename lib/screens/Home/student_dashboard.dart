import 'package:flutter/material.dart';

class CasualDashboard extends StatelessWidget {
  const CasualDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final tasks = [
      "Log one shower today",
      "Try 2-min shorter wash",
      "Fill a bottle instead of running tap",
      "Use a bowl for veggie washing",
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("🎮 Casual Dashboard", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        const Text("Quick tasks to get familiar:", style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 8),
        ...tasks.map((t) => Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: const Icon(Icons.check_circle_outline),
            title: Text(t),
            trailing: const Icon(Icons.chevron_right),
          ),
        )),
      ],
    );
  }
}
