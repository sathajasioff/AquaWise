import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:watermeter/screens/AI/AItips.dart';
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
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
            decoration: InputDecoration(
              hintText: "e.g. 5000",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
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

  // Navigation to AI Awareness and Tips page
  void _navigateToAiTips() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AIPersonalizationPage()),
    );
  }

  // Navigation to Report Generator page
  void _navigateToReportGenerator() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ReportGeneratorPage()),
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
      backgroundColor: const Color(0xFFF8FAFD),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A2B47),
        title: Text(
          "Welcome, ${currentUser?.username ?? 'username'}",
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
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
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF2D7DD2),
        ),
      );
    }

    final remaining = _budgetLiters - _litersUsed;
    final percentage = (_litersUsed / _budgetLiters).clamp(0, 1);
    final Color progressColor = percentage > 0.8 
        ? Colors.orange 
        : percentage > 0.6 
            ? Colors.yellow[700]! 
            : const Color(0xFF2D7DD2);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Monthly summary card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2D7DD2), Color(0xFF1A5FA6)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.water_drop, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      "Monthly Water Budget",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Stack(
                  children: [
                    LinearProgressIndicator(
                      value: percentage.toDouble(),
                      minHeight: 16,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                      valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                    ),
                    if (percentage > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          width: 4,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${_litersUsed.toStringAsFixed(1)} L",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const Text(
                          "Used",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "${_budgetLiters.toStringAsFixed(0)} L",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const Text(
                          "Budget",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Remaining:",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        "${remaining.toStringAsFixed(1)} L",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // AI Awareness & Tips Card
          GestureDetector(
            onTap: _navigateToAiTips,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.auto_awesome, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "AI Water Saving Tips",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Get personalized water conservation advice",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          
          // Budget card
          GestureDetector(
            onTap: _setBudget,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F2FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.calendar_month, color: Color(0xFF2D7DD2)),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Set Your Monthly Budget",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Customize your water usage limit",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.grey,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),

          // Timer section
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Track Water Usage",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A2B47),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Start timer when using water and stop when done",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _activity,
                            items: const [
                              DropdownMenuItem(value: "Bathing", child: Text("Bathing")),
                              DropdownMenuItem(value: "Cleaning", child: Text("Cleaning")),
                              DropdownMenuItem(value: "Washing", child: Text("Washing")),
                              DropdownMenuItem(value: "Cooking", child: Text("Cooking")),
                            ],
                            onChanged: (v) => setState(() => _activity = v!),
                            style: const TextStyle(
                              color: Color(0xFF1A2B47),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: ElevatedButton.icon(
                        onPressed: _isTiming ? _stopTimer : _startTimer,
                        icon: Icon(
                          _isTiming ? Icons.stop_circle_outlined : Icons.play_circle_filled_outlined,
                          size: 22,
                        ),
                        label: Text(_isTiming ? "STOP" : "START"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isTiming ? Colors.red : const Color(0xFF2D7DD2),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "Current Session",
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "$_seconds seconds",
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A2B47),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "~${(_seconds / 60 * 10).toStringAsFixed(1)} liters",
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Chart + Logs section
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Water Usage Overview",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A2B47),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Track your consumption patterns over time",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 20),
                StreamBuilder<List<WaterUsage>>(
                  stream: _controller.usageStream(),
                  builder: (context, snap) {
                    final logs = snap.data ?? const <WaterUsage>[];
                    if (!snap.hasData) {
                      return Container(
                        height: 200,
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF2D7DD2),
                          ),
                        ),
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        UsageChart(usageLogs: logs),
                        const SizedBox(height: 24),
                        const Text(
                          "Recent Activity",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A2B47),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (logs.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(40),
                            child: Column(
                              children: [
                                Icon(Icons.water_drop_outlined, 
                                    color: Colors.grey.shade400, size: 48),
                                const SizedBox(height: 12),
                                const Text(
                                  "No usage logs yet",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  "Start tracking your water usage to see data here",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          ...logs.take(6).map(
                                (l) => Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE8F2FF),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Icon(Icons.water_drop,
                                            color: Color(0xFF2D7DD2), size: 18),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              l.activity,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              l.date
                                                  .toString()
                                                  .split(".")[0]
                                                  .replaceAll("T", "  "),
                                              style: const TextStyle(
                                                color: Colors.grey,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        "${l.liters.toStringAsFixed(1)} L",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF1A2B47),
                                        ),
                                      ),
                                    ],
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

          // Report Generator Card - NEW ADDITION
          GestureDetector(
            onTap: _navigateToReportGenerator,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF00B894), Color(0xFF00A085)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.analytics, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Generate Reports",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "View detailed water usage analytics",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),


          // Persona dashboard section
          _personaSection(currentUser!.persona ?? 'casual'),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// Placeholder for Report Generator Page - Replace with your actual implementation
class ReportGeneratorPage extends StatelessWidget {
  const ReportGeneratorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Water Usage Reports'),
        backgroundColor: const Color(0xFF00B894),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Text(
            'Generate detailed reports of your past water usage activities from Firebase.',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

