import 'package:flutter/material.dart';

class BudgetDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        Text("💰 Budget-Conscious Dashboard",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        SizedBox(height: 12),
        Card(
          child: ListTile(
            title: Text("Current Bill Forecast"),
            subtitle: Text("Rs. 540 this month (↓10% from last month)"),
          ),
        ),
        Card(
          child: ListTile(
            title: Text("Suggestions"),
            subtitle: Text("Shorten showers by 2 mins → Save Rs. 80"),
          ),
        ),
      ],
    );
  }
}
