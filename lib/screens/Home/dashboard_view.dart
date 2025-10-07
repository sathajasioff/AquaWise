import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import '../../controllers/dashboard_controller.dart';
import '../../models/user.dart';
import '../../models/usage_model.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({Key? key}) : super(key: key);

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  final DashboardController _controller = DashboardController();
  User? currentUser;

  // Timer variables
  bool _isTiming = false;
  Timer? _timer;
  int _seconds = 0;
  String _activity = 'Bathing';
  double _budgetLiters = 5000;
  double _litersUsed = 0;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadMonthlyData();
  }

  Future<void> _loadUser() async {
    final userData = await _controller.fetchUser();
    setState(() => currentUser = userData);
  }

  void _loadMonthlyData() async {
    final total = await _controller.getMonthlyTotal();
    setState(() => _litersUsed = total);
  }

  void _startTimer() {
    setState(() => _isTiming = true);
    _seconds = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() => _seconds++);
    });
  }

  void _stopTimer() async {
    _timer?.cancel();
    setState(() => _isTiming = false);

    // Simple conversion (10L/min)
    final liters = (_seconds / 60) * 10;
    await _controller.logWaterUsage(_activity, liters);
    _loadMonthlyData();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Logged $_activity: ${liters.toStringAsFixed(1)} L")),
    );
  }

  void _setBudget() {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text("Set Monthly Budget (Liters)"),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: "Enter liters"),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() =>
                    _budgetLiters = double.tryParse(controller.text) ?? 5000);
                Navigator.pop(context);
              },
              child: const Text("Save"),
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final remaining = _budgetLiters - _litersUsed;
    final percentage = (_litersUsed / _budgetLiters).clamp(0, 1);

    return Scaffold(
      appBar: AppBar(
        title: Text("Welcome, ${currentUser!.name}"),
        actions: [
          IconButton(onPressed: _setBudget, icon: const Icon(Icons.settings)),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Monthly Summary ---
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      "Monthly Water Budget",
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: percentage.toDouble(),
                      minHeight: 10,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "${_litersUsed.toStringAsFixed(1)} L used / ${_budgetLiters.toStringAsFixed(0)} L budgeted",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "Remaining: ${remaining.toStringAsFixed(1)} L",
                      style: const TextStyle(color: Colors.green),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // --- Activity Timer ---
            Row(
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _activity,
                    items: const [
                      DropdownMenuItem(value: "Bathing", child: Text("Bathing")),
                      DropdownMenuItem(value: "Cleaning", child: Text("Cleaning")),
                      DropdownMenuItem(value: "Washing", child: Text("Washing")),
                      DropdownMenuItem(value: "Cooking", child: Text("Cooking")),
                    ],
                    onChanged: (val) => setState(() => _activity = val!),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: _isTiming ? _stopTimer : _startTimer,
                  icon: Icon(_isTiming ? Icons.stop : Icons.play_arrow),
                  label: Text(_isTiming ? "Stop" : "Start"),
                ),
              ],
            ),

            const SizedBox(height: 20),
            Center(
              child: Text(
                "Timer: $_seconds s",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 30),
            const Text(
              "Recent Logs",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            StreamBuilder<List<WaterUsage>>(
              stream: _controller.getUsageLogs(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final logs = snapshot.data!;
                if (logs.isEmpty) {
                  return const Text("No usage logs yet.");
                }
                return Column(
                  children: logs
                      .map((log) => ListTile(
                            leading: const Icon(Icons.water_drop, color: Colors.blue),
                            title: Text("${log.activity} - ${log.liters.toStringAsFixed(1)} L"),
                            subtitle: Text(
                              log.date.toString().split(".")[0],
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
