import 'package:flutter/material.dart';

class StudentDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        Text("🎯 Student / Young Pro Dashboard",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        SizedBox(height: 12),
        Card(
          child: ListTile(
            title: Text("Current Streak"),
            subtitle: Text("🔥 7 Days Active"),
          ),
        ),
        Card(
          child: ListTile(
            title: Text("Leaderboard"),
            subtitle: Text("You are #3 among your friends"),
          ),
        ),
      ],
    );
  }
}
