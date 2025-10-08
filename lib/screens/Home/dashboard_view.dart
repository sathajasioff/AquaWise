import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:watermeter/widgets/dashboard_navbar.dart';
import '../../controllers/dashboard_controller.dart';
import '../../models/user.dart';
import '../../models/usage_model.dart';
import '../../widgets/usage_chart.dart';
import '../../settings/settings.dart';

// persona screens
import '../Home/eco_dashboard.dart';
import '../Home/family_dashboard.dart';
import '../Home/budget_dashboard.dart';
import '../Home/student_dashboard.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({Key? key}) : super(key: key);
  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  final DashboardController _controller = DashboardController();
  User? currentUser;

  bool _isTiming = false;
  Timer? _timer;
  int _seconds = 0;
  String _activity = 'Bathing';
  double _budgetLiters = 5000;
  double _litersUsed = 0;

  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadMonthlyData();
  }

  Future<void> _loadUser() async {
    final u = await _controller.fetchUser();
    setState(() => currentUser = u);
  }

  void _loadMonthlyData() async {
    final total = await _controller.monthlyTotalLiters();
    setState(() => _litersUsed = total);
  }

  void _startTimer() {
    setState(() => _isTiming = true);
    _seconds = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _seconds++);
    });
  }

  void _stopTimer() async {
    _timer?.cancel();
    setState(() => _isTiming = false);
    final liters = (_seconds / 60) * 10;
    await _controller.logWaterUsage(_activity, liters);
    _loadMonthlyData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Logged $_activity: ${liters.toStringAsFixed(1)} L"),
        ),
      );
    }
  }

  void _setBudget() {
    showDialog(
      context: context,
      builder: (_) {
        final txt = TextEditingController(
          text: _budgetLiters.toStringAsFixed(0),
        );
        return AlertDialog(
          title: const Text("Set Monthly Budget (Liters)"),
          content: TextField(
            controller: txt,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: "e.g. 5000"),
          ),
          actions: [
            TextButton(
              onPressed: () {
                final v = double.tryParse(txt.text.trim());
                if (v != null) setState(() => _budgetLiters = v);
                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  Widget _personaSection(String persona) {
    final type = persona.toLowerCase();
    if (type.contains('eco')) {
      return EcoDashboard(controller: _controller);
    } else if (type.contains('family')) {
      return FamilyDashboard(controller: _controller);
    } else if (type.contains('budget')) {
      return BudgetDashboard(controller: _controller);
    } else {
      return const CasualDashboard();
    }
  }

  // 🧭 Navigation pages
  Widget _getSelectedScreen() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboardBody();
      case 1:
        return const Center(child: Text("Profile Screen"));
      case 3:
        return const Center(child: Text("Settings Screen"));
      default:
        return _buildDashboardBody();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: Text(
          "Welcome, ${currentUser?.name ?? 'User'}",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _getSelectedScreen(),
      bottomNavigationBar: DashboardNavBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
      ),
    );
  }

  // 💧 The actual dashboard content separated for cleaner code
  Widget _buildDashboardBody() {
    if (currentUser == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final remaining = _budgetLiters - _litersUsed;
    final percentage = (_litersUsed / _budgetLiters).clamp(0, 1);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Monthly summary
          Card(
            color: Colors.white,
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.water_drop, color: Colors.blueAccent),
                      SizedBox(width: 8),
                      Text(
                        "Monthly Water Budget",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: percentage.toDouble(),
                    minHeight: 10,
                    backgroundColor: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(10),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.lightBlueAccent),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${_litersUsed.toStringAsFixed(1)} L used",
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        "${_budgetLiters.toStringAsFixed(0)} L budget",
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Remaining: ${remaining.toStringAsFixed(1)} L",
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Budget card
          GestureDetector(
            onTap: _setBudget,
            child: Card(
              color: Colors.blueAccent.shade100.withOpacity(0.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: const ListTile(
                leading: Icon(Icons.calendar_month, color: Colors.blueAccent),
                title: Text(
                  "Set Your Monthly Budget",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.blueAccent,
                  size: 18,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Timer
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Track Your Water Usage",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          fillColor: Colors.grey.shade100,
                          filled: true,
                        ),
                        value: _activity,
                        items: const [
                          DropdownMenuItem(value: "Bathing", child: Text("Bathing")),
                          DropdownMenuItem(value: "Cleaning", child: Text("Cleaning")),
                          DropdownMenuItem(value: "Washing", child: Text("Washing")),
                          DropdownMenuItem(value: "Cooking", child: Text("Cooking")),
                        ],
                        onChanged: (v) => setState(() => _activity = v!),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: _isTiming ? _stopTimer : _startTimer,
                      icon:
                          Icon(_isTiming ? Icons.stop : Icons.play_arrow_outlined),
                      label: Text(_isTiming ? "Stop" : "Start"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _isTiming ? Colors.redAccent : Colors.blueAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    "Timer: $_seconds s",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Chart + Logs
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Water Usage Overview",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                StreamBuilder<List<WaterUsage>>(
                  stream: _controller.usageStream(),
                  builder: (context, snap) {
                    final logs = snap.data ?? const <WaterUsage>[];
                    if (!snap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        UsageChart(usageLogs: logs),
                        const SizedBox(height: 16),
                        const Text(
                          "Recent Activity Logs",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        if (logs.isEmpty)
                          const Text("No usage logs yet.")
                        else
                          ...logs.take(8).map(
                                (l) => ListTile(
                                  dense: true,
                                  leading: const Icon(Icons.water_drop,
                                      color: Colors.blueAccent),
                                  title: Text(
                                      "${l.activity} - ${l.liters.toStringAsFixed(1)} L"),
                                  subtitle: Text(
                                    l.date
                                        .toString()
                                        .split(".")[0]
                                        .replaceAll("T", "  "),
                                  ),
                                ),
                              ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Persona dashboard section
          _personaSection(currentUser!.persona ?? 'casual'),
        ],
      ),
    );
  }
}
