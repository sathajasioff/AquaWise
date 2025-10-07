import 'package:flutter/material.dart';

class FamilyDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        Text("👨‍👩‍👧 Family Manager Dashboard",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        SizedBox(height: 12),
        Card(
          child: ListTile(
            title: Text("Household Breakdown"),
            subtitle: Text("Shower: 50L | Laundry: 30L | Kids: 20L"),
          ),
        ),
        Card(
          child: ListTile(
            title: Text("Reminders"),
            subtitle: Text("8PM Laundry Alert Enabled"),
          ),
        ),
      ],
    );
  }
}
