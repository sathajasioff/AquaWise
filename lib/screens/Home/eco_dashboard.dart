import 'package:flutter/material.dart';
import '../../controllers/dashboard_controller.dart';

class EcoDashboard extends StatefulWidget {
  final DashboardController controller;
  const EcoDashboard({super.key, required this.controller});

  @override
  State<EcoDashboard> createState() => _EcoDashboardState();
}

class _EcoDashboardState extends State<EcoDashboard> {
  late Future<Map<String, dynamic>> _dashboardData;

  @override
  void initState() {
    super.initState();
    _dashboardData = widget.controller.getEcoDashboardData();
  }

  void _refreshData() {
    setState(() {
      _dashboardData = widget.controller.getEcoDashboardData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        _refreshData();
      },
      child: FutureBuilder<Map<String, dynamic>>(
        future: _dashboardData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingState();
          }

          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          }

          final data = snapshot.data ?? {};
          return _buildDashboardContent(data);
        },
      ),
    );
  }

  Widget _buildDashboardContent(Map<String, dynamic> data) {
    final thisWeekUsage = _safeToDouble(data['thisWeekUsage']) ?? 0.0;
    final lastWeekUsage = _safeToDouble(data['lastWeekUsage']) ?? 0.0;
    final waterSaved = _safeToDouble(data['waterSaved']) ?? 0.0;
    final savingsPercentage = _safeToDouble(data['savingsPercentage']) ?? 0.0;
    final co2Reduced = _safeToDouble(data['co2Reduced']) ?? 0.0;
    final moneySaved = _safeToDouble(data['moneySaved']) ?? 0.0;
    final currentStreak = (data['currentStreak'] as int?) ?? 0;
    final badges = (data['badges'] as List<dynamic>?)?.cast<String>() ?? <String>[];
    final recommendations = (data['recommendations'] as List<dynamic>?)?.cast<String>() ?? <String>[];
    final dailyBreakdown = _convertDailyBreakdown(data['dailyBreakdown']);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                "🌱 Eco Dashboard",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _refreshData,
                tooltip: 'Refresh data',
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Quick Stats Row
          _buildQuickStats(waterSaved, co2Reduced, moneySaved),
          const SizedBox(height: 16),
          
          // Weekly Comparison
          _buildWeeklyComparison(thisWeekUsage, lastWeekUsage, savingsPercentage),
          const SizedBox(height: 16),
          
          // Daily Breakdown
          if (dailyBreakdown.isNotEmpty) ...[
            _buildDailyBreakdown(dailyBreakdown),
            const SizedBox(height: 16),
          ],
          
          // Current Streak
          _buildStreakCard(currentStreak),
          const SizedBox(height: 16),
          
          // Badges Section
          _buildBadgesSection(badges),
          const SizedBox(height: 16),
          
          // Smart Recommendations
          _buildRecommendationsSection(recommendations),
          const SizedBox(height: 16),
          
          // Water Impact Visualization
          _buildImpactVisualization(waterSaved),
        ],
      ),
    );
  }

  double _safeToDouble(dynamic value) {
    if (value == null) return 0.0;
    
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    if (value is num) return value.toDouble();
    
    return 0.0;
  }

  // Helper method to convert daily breakdown map
  Map<String, double> _convertDailyBreakdown(dynamic breakdown) {
    if (breakdown is! Map) return {};
    
    final result = <String, double>{};
    breakdown.forEach((key, value) {
      final doubleValue = _safeToDouble(value);
      if (key is String) {
        result[key] = doubleValue;
      }
    });
    return result;
  }

  Widget _buildQuickStats(double waterSaved, double co2Reduced, double moneySaved) {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            "Water Saved",
            "${waterSaved.toStringAsFixed(0)}L",
            Icons.water_drop,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(
            "CO₂ Reduced",
            "${co2Reduced.toStringAsFixed(1)}kg",
            Icons.eco,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(
            "Money Saved",
            "\$${moneySaved.toStringAsFixed(2)}",
            Icons.attach_money,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyComparison(double thisWeek, double lastWeek, double savingsPct) {
    final isSaving = savingsPct > 0;
    
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isSaving ? Icons.trending_down : Icons.trending_up, 
                  color: isSaving ? Colors.green : Colors.red
                ),
                const SizedBox(width: 8),
                Text(
                  "Weekly Comparison",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isSaving ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _comparisonItem("This Week", "${thisWeek.toStringAsFixed(0)}L", Colors.blue),
                ),
                Expanded(
                  child: _comparisonItem("Last Week", "${lastWeek.toStringAsFixed(0)}L", Colors.grey),
                ),
                Expanded(
                  child: _comparisonItem(
                    isSaving ? "Savings" : "Increase", 
                    "${savingsPct.abs().toStringAsFixed(1)}%", 
                    isSaving ? Colors.green : Colors.red
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: lastWeek > 0 ? thisWeek / lastWeek : 0,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                isSaving ? Colors.green : Colors.orange,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyBreakdown(Map<String, double> dailyBreakdown) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final maxUsage = dailyBreakdown.values.reduce((a, b) => a > b ? a : b);
    
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "📊 Daily Usage",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: days.map((day) {
                final usage = dailyBreakdown[day] ?? 0.0;
                final height = maxUsage > 0 ? (usage / maxUsage * 40) : 0.0;
                
                return Column(
                  children: [
                    Container(
                      width: 20,
                      height: height,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      day.substring(0, 1),
                      style: const TextStyle(fontSize: 10),
                    ),
                    Text(
                      '${usage.toStringAsFixed(0)}L',
                      style: const TextStyle(fontSize: 9),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakCard(int streak) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.local_fire_department, color: Colors.orange, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "$streak Day Streak!",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    "Keep saving water to maintain your streak",
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            if (streak > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "🔥",
                  style: const TextStyle(fontSize: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgesSection(List<String> badges) {
    final allBadges = [
      'Low-flow Hero',
      'Shower Saver',
      'Leak Detective',
      'Eco Warrior',
      'Water Guardian',
      'Conservation Champion',
      'Smart User',
      'Early Saver',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "🏆 Your Badges",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: allBadges.map((badge) {
            final hasBadge = badges.contains(badge);
            return _Badge(
              text: badge,
              isUnlocked: hasBadge,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRecommendationsSection(List<String> recommendations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "💡 Smart Recommendations",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        ...recommendations.take(3).map((recommendation) => _recommendationCard(recommendation)),
      ],
    );
  }

  Widget _buildImpactVisualization(double waterSaved) {
    final treesSaved = (waterSaved / 1000).floor(); // Rough estimate: 1000L saves 1 tree
    final showersSaved = (waterSaved / 60).floor(); // Average shower uses 60L
    
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "🌍 Your Water Impact",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _impactItem("🚿", "$showersSaved", "Showers Saved"),
                _impactItem("🌳", "$treesSaved", "Trees Protected"),
                _impactItem("💧", "${waterSaved.toStringAsFixed(0)}L", "Water Conserved"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            Text(
              title,
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _comparisonItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _recommendationCard(String recommendation) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.blue[50],
      child: ListTile(
        leading: const Icon(Icons.lightbulb_outline, color: Colors.blue),
        title: Text(
          recommendation,
          style: const TextStyle(fontSize: 14),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.arrow_forward, size: 16),
          onPressed: () {
            // Implement recommendation action
          },
        ),
      ),
    );
  }

  Widget _impactItem(String emoji, String value, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading your eco data...'),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text('Error loading data: $error', textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _refreshData,
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final bool isUnlocked;
  
  const _Badge({required this.text, this.isUnlocked = false});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isUnlocked ? Colors.green.withOpacity(0.15) : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isUnlocked ? Colors.green : Colors.grey.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isUnlocked ? Icons.check_circle : Icons.lock,
            size: 14,
            color: isUnlocked ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: isUnlocked ? Colors.green : Colors.grey,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}