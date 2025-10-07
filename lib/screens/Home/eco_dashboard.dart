import 'package:flutter/material.dart';

class EcoDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        Text("🌱 Eco-Conscious Dashboard",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        SizedBox(height: 12),
        Card(
          child: ListTile(
            title: Text("Total Liters Saved"),
            subtitle: Text("120 L vs. 150 L last week"),
          ),
        ),
        Card(
          child: ListTile(
            title: Text("CO₂ Saved"),
            subtitle: Text("≈ 3.5 kg"),
          ),
        ),
      ],
    );
  }
}
