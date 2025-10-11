import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class WaterFootprintCalculator extends StatefulWidget {
  const WaterFootprintCalculator({super.key});

  @override
  State<WaterFootprintCalculator> createState() => _WaterFootprintCalculatorState();
}

class _WaterFootprintCalculatorState extends State<WaterFootprintCalculator> {
  // Water Footprint Calculator State
  Map<String, double> _userInputs = {
    'showerDuration': 10.0,
    'showerFrequency': 1.0,
    'bathFrequency': 0.0,
    'laundryLoads': 3.0,
    'dishwashingMethod': 0.0, // 0 = machine, 1 = hand
    'dishwashingFrequency': 1.0,
    'gardenWatering': 10.0, // minutes per week
    'carWashFrequency': 1.0,
    'toiletFlushes': 5.0,
    'teethBrushing': 2.0,
    'handWashing': 5.0,
  };

  double _totalFootprint = 0.0;
  Map<String, double> _categoryBreakdown = {};
  String _footprintLevel = 'Average';
  List<Map<String, dynamic>> _improvementSuggestions = [];
  bool _showCalculator = false;
  List<Map<String, dynamic>> _footprintHistory = [];
  bool _isLoadingHistory = false;
  
  // Water usage constants (liters)
  final Map<String, double> _waterConstants = {
    'showerPerMinute': 9.0,
    'bath': 80.0,
    'laundryLoad': 50.0,
    'dishwashingMachine': 15.0,
    'dishwashingHand': 30.0,
    'gardenWateringPerMinute': 10.0,
    'carWash': 100.0,
    'toiletFlush': 6.0,
    'teethBrushingTapOpen': 6.0,
    'handWashingPerWash': 2.0,
  };

  @override
  void initState() {
    super.initState();
    _loadFootprintHistory();
  }

  /// Save footprint calculation to Firestore
  Future<void> _saveFootprintToFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('User not authenticated, skipping save');
      return;
    }

    try {
      final footprintData = {
        'userId': user.uid,
        'userEmail': user.email,
        'totalFootprint': _totalFootprint,
        'footprintLevel': _footprintLevel,
        'categoryBreakdown': _categoryBreakdown,
        'userInputs': _userInputs,
        'improvementSuggestions': _improvementSuggestions,
        'timestamp': FieldValue.serverTimestamp(),
        'date': DateTime.now().toIso8601String(),
      };

      await FirebaseFirestore.instance
          .collection('waterFootprints')
          .add(footprintData);

      print('✅ Footprint saved to Firestore: ${_totalFootprint.toStringAsFixed(0)}L');
      
      // Reload history
      _loadFootprintHistory();
      
      // Show success feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Footprint saved to your history!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

    } catch (e) {
      print('❌ Error saving to Firestore: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save footprint: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Load user's footprint history
  Future<void> _loadFootprintHistory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoadingHistory = true);

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('waterFootprints')
          .where('userId', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .limit(10) // Last 10 calculations
          .get();

      setState(() {
        _footprintHistory = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'totalFootprint': data['totalFootprint'] ?? 0.0,
            'footprintLevel': data['footprintLevel'] ?? 'Average',
            'date': data['date'] ?? DateTime.now().toIso8601String(),
            'timestamp': data['timestamp'],
          };
        }).toList();
      });
    } catch (e) {
      print('Error loading footprint history: $e');
    } finally {
      setState(() => _isLoadingHistory = false);
    }
  }

  /// Calculate water footprint
  void _calculateFootprint() {
    double total = 0.0;
    Map<String, double> breakdown = {};

    // Shower calculation
    double showerDaily = _userInputs['showerDuration']! * 
                        _waterConstants['showerPerMinute']! * 
                        _userInputs['showerFrequency']!;
    breakdown['Shower'] = showerDaily;
    total += showerDaily;

    // Bath calculation
    double bathDaily = _userInputs['bathFrequency']! * _waterConstants['bath']!;
    breakdown['Bath'] = bathDaily;
    total += bathDaily;

    // Laundry calculation (weekly to daily)
    double laundryDaily = (_userInputs['laundryLoads']! * 
                          _waterConstants['laundryLoad']!) / 7;
    breakdown['Laundry'] = laundryDaily;
    total += laundryDaily;

    // Dishwashing calculation
    double dishwashingDaily = _userInputs['dishwashingFrequency']! * 
        (_userInputs['dishwashingMethod']! == 0 ? 
         _waterConstants['dishwashingMachine']! : 
         _waterConstants['dishwashingHand']!);
    breakdown['Dishwashing'] = dishwashingDaily;
    total += dishwashingDaily;

    // Garden watering (weekly to daily)
    double gardenDaily = (_userInputs['gardenWatering']! * 
                         _waterConstants['gardenWateringPerMinute']!) / 7;
    breakdown['Garden'] = gardenDaily;
    total += gardenDaily;

    // Car wash (weekly to daily)
    double carDaily = (_userInputs['carWashFrequency']! * 
                      _waterConstants['carWash']!) / 7;
    breakdown['Car Wash'] = carDaily;
    total += carDaily;

    // Toilet flushes
    double toiletDaily = _userInputs['toiletFlushes']! * 
                        _waterConstants['toiletFlush']!;
    breakdown['Toilet'] = toiletDaily;
    total += toiletDaily;

    // Personal hygiene
    double teethBrushingDaily = _userInputs['teethBrushing']! * 
                               _waterConstants['teethBrushingTapOpen']!;
    double handWashingDaily = _userInputs['handWashing']! * 
                             _waterConstants['handWashingPerWash']!;
    breakdown['Personal Hygiene'] = teethBrushingDaily + handWashingDaily;
    total += teethBrushingDaily + handWashingDaily;

    // Determine footprint level
    String level;
    if (total < 100) level = 'Excellent';
    else if (total < 150) level = 'Good';
    else if (total < 200) level = 'Average';
    else level = 'High';

    // Generate improvement suggestions
    _generateImprovementSuggestions(breakdown, total);

    setState(() {
      _totalFootprint = total;
      _categoryBreakdown = breakdown;
      _footprintLevel = level;
    });

    // Save to Firestore
    _saveFootprintToFirestore();
  }

  /// Generate personalized improvement suggestions
  void _generateImprovementSuggestions(Map<String, double> breakdown, double total) {
    List<Map<String, dynamic>> suggestions = [];

    if (breakdown['Shower']! > 50) {
      suggestions.add({
        'title': 'Reduce Shower Time',
        'description': 'Try reducing your shower time by 2 minutes to save ${(2 * _waterConstants['showerPerMinute']! * _userInputs['showerFrequency']!).toStringAsFixed(1)}L daily',
        'savings': 2 * _waterConstants['showerPerMinute']! * _userInputs['showerFrequency']!,
        'priority': 'high'
      });
    }

    if (breakdown['Laundry']! > 20) {
      suggestions.add({
        'title': 'Optimize Laundry',
        'description': 'Wait for full loads and use eco-mode to save up to 30% water',
        'savings': breakdown['Laundry']! * 0.3,
        'priority': 'medium'
      });
    }

    if (_userInputs['dishwashingMethod']! == 1 && breakdown['Dishwashing']! > 15) {
      suggestions.add({
        'title': 'Use Dishwasher Efficiently',
        'description': 'Dishwashers use 50% less water than hand washing',
        'savings': breakdown['Dishwashing']! * 0.5,
        'priority': 'high'
      });
    }

    if (breakdown['Garden']! > 15) {
      suggestions.add({
        'title': 'Smart Garden Watering',
        'description': 'Water plants early morning to reduce evaporation',
        'savings': breakdown['Garden']! * 0.2,
        'priority': 'medium'
      });
    }

    if (breakdown['Personal Hygiene']! > 15) {
      suggestions.add({
        'title': 'Turn Off Tap',
        'description': 'Turn off tap while brushing teeth to save 6L per brush',
        'savings': _userInputs['teethBrushing']! * _waterConstants['teethBrushingTapOpen']!,
        'priority': 'high'
      });
    }

    setState(() {
      _improvementSuggestions = suggestions;
    });
  }

  /// Reset calculator
  void _resetCalculator() {
    setState(() {
      _userInputs = {
        'showerDuration': 10.0,
        'showerFrequency': 1.0,
        'bathFrequency': 0.0,
        'laundryLoads': 3.0,
        'dishwashingMethod': 0.0,
        'dishwashingFrequency': 1.0,
        'gardenWatering': 10.0,
        'carWashFrequency': 1.0,
        'toiletFlushes': 5.0,
        'teethBrushing': 2.0,
        'handWashing': 5.0,
      };
      _totalFootprint = 0.0;
      _categoryBreakdown = {};
      _improvementSuggestions = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF00B894).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.calculate_outlined,
                  color: Color(0xFF00B894),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Water Footprint Calculator",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A2B47),
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _showCalculator = !_showCalculator;
                  });
                },
                icon: Icon(
                  _showCalculator ? Icons.expand_less : Icons.expand_more,
                  color: const Color(0xFF2D7DD2),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          Text(
            "Discover your daily water usage and get personalized tips",
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),

          // Calculator Content (Collapsible)
          if (_showCalculator) ...[
            const SizedBox(height: 20),

            // Input Section
            _buildInputSection(),

            const SizedBox(height: 24),

            // Calculate Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _calculateFootprint,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00B894),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.calculate, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      "Calculate My Footprint",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Results Section
            if (_totalFootprint > 0) _buildResultsSection(),

            // History Section
            if (_footprintHistory.isNotEmpty) _buildHistorySection(),
          ],
        ],
      ),
    );
  }

  /// Input Section Widget
  Widget _buildInputSection() {
    return Column(
      children: [
        _buildSliderInput(
          label: "Shower Duration",
          value: _userInputs['showerDuration']!,
          min: 2,
          max: 30,
          unit: "minutes",
          icon: Icons.shower,
          onChanged: (value) {
            setState(() {
              _userInputs['showerDuration'] = value;
            });
          },
        ),

        _buildSliderInput(
          label: "Showers per Day",
          value: _userInputs['showerFrequency']!,
          min: 0,
          max: 3,
          unit: "times",
          icon: Icons.repeat,
          onChanged: (value) {
            setState(() {
              _userInputs['showerFrequency'] = value;
            });
          },
        ),

        _buildSliderInput(
          label: "Laundry Loads per Week",
          value: _userInputs['laundryLoads']!,
          min: 0,
          max: 10,
          unit: "loads",
          icon: Icons.local_laundry_service,
          onChanged: (value) {
            setState(() {
              _userInputs['laundryLoads'] = value;
            });
          },
        ),

        // Dishwashing Method Toggle
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.kitchen, color: const Color(0xFF2D7DD2), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    "Dishwashing Method",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: Text("Dishwasher"),
                      selected: _userInputs['dishwashingMethod'] == 0,
                      onSelected: (selected) {
                        setState(() {
                          _userInputs['dishwashingMethod'] = 0;
                        });
                      },
                      selectedColor: const Color(0xFF00B894),
                      labelStyle: GoogleFonts.poppins(
                        color: _userInputs['dishwashingMethod'] == 0 ? Colors.white : Colors.grey.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: Text("Hand Wash"),
                      selected: _userInputs['dishwashingMethod'] == 1,
                      onSelected: (selected) {
                        setState(() {
                          _userInputs['dishwashingMethod'] = 1;
                        });
                      },
                      selectedColor: const Color(0xFF00B894),
                      labelStyle: GoogleFonts.poppins(
                        color: _userInputs['dishwashingMethod'] == 1 ? Colors.white : Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        _buildSliderInput(
          label: "Garden Watering(weekly)",
          value: _userInputs['gardenWatering']!,
          min: 0,
          max: 60,
          unit: "minutes",
          icon: Icons.nature,
          onChanged: (value) {
            setState(() {
              _userInputs['gardenWatering'] = value;
            });
          },
        ),
      ],
    );
  }

  /// Reusable Slider Input Widget
  Widget _buildSliderInput({
    required String label,
    required double value,
    required double min,
    required double max,
    required String unit,
    required IconData icon,
    required Function(double) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF2D7DD2), size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                "${value.toStringAsFixed(0)} $unit",
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2D7DD2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: (max - min).toInt(),
            onChanged: onChanged,
            activeColor: const Color(0xFF00B894),
            inactiveColor: Colors.grey.shade300,
          ),
        ],
      ),
    );
  }

  /// Results Section Widget
  Widget _buildResultsSection() {
    return Column(
      children: [
        const SizedBox(height: 24),
        
        // Total Footprint Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _getFootprintGradient(),
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getFootprintIcon(),
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Daily Water Footprint",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    Text(
                      "${_totalFootprint.toStringAsFixed(0)} Liters",
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      _footprintLevel,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Breakdown Section
        Text(
          "Usage Breakdown",
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1A2B47),
          ),
        ),
        const SizedBox(height: 12),
        ..._categoryBreakdown.entries.map((entry) => 
          _buildBreakdownItem(entry.key, entry.value)
        ).toList(),

        // Improvement Suggestions
        if (_improvementSuggestions.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(
            "Personalized Improvement Tips",
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A2B47),
            ),
          ),
          const SizedBox(height: 12),
          ..._improvementSuggestions.map((suggestion) => 
            _buildSuggestionCard(suggestion)
          ).toList(),
        ],

        // Reset Button
        const SizedBox(height: 20),
        OutlinedButton(
          onPressed: _resetCalculator,
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF2D7DD2),
            side: const BorderSide(color: Color(0xFF2D7DD2)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: Text(
            'Reset Calculator',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  /// History Section Widget
  Widget _buildHistorySection() {
    return Column(
      children: [
        const SizedBox(height: 24),
        Text(
          "Recent Calculations",
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1A2B47),
          ),
        ),
        const SizedBox(height: 12),
        ..._footprintHistory.take(3).map((history) => 
          _buildHistoryItem(history)
        ).toList(),
      ],
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> history) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.history,
            color: const Color(0xFF2D7DD2),
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "${history['totalFootprint'].toStringAsFixed(0)}L - ${history['footprintLevel']}",
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            _formatDate(history['date']),
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Recent';
    }
  }

  /// Helper Methods
  List<Color> _getFootprintGradient() {
    switch (_footprintLevel) {
      case 'Excellent':
        return [const Color(0xFF00B894), const Color(0xFF00A085)];
      case 'Good':
        return [const Color(0xFF2D7DD2), const Color(0xFF1A5FA6)];
      case 'Average':
        return [const Color(0xFFFF9A3D), const Color(0xFFF57C00)];
      case 'High':
        return [const Color(0xFFFF6B6B), const Color(0xFFEE5A52)];
      default:
        return [const Color(0xFF2D7DD2), const Color(0xFF1A5FA6)];
    }
  }

  IconData _getFootprintIcon() {
    switch (_footprintLevel) {
      case 'Excellent':
        return Icons.eco;
      case 'Good':
        return Icons.thumb_up;
      case 'Average':
        return Icons.info;
      case 'High':
        return Icons.warning;
      default:
        return Icons.info;
    }
  }

  Widget _buildBreakdownItem(String category, double value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              category,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            "${value.toStringAsFixed(0)}L",
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2D7DD2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionCard(Map<String, dynamic> suggestion) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getSuggestionColor(suggestion['priority']),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getSuggestionBorderColor(suggestion['priority']),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lightbulb_outline,
            color: _getSuggestionIconColor(suggestion['priority']),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  suggestion['title'],
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _getSuggestionTextColor(suggestion['priority']),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  suggestion['description'],
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: _getSuggestionTextColor(suggestion['priority']),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Potential savings: ${suggestion['savings'].toStringAsFixed(1)}L daily",
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _getSuggestionTextColor(suggestion['priority']),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Color helpers for suggestions
  Color _getSuggestionColor(String priority) {
    switch (priority) {
      case 'high':
        return const Color(0xFFFFF2F2);
      case 'medium':
        return const Color(0xFFFFF9E6);
      default:
        return const Color(0xFFF0F7FF);
    }
  }

  Color _getSuggestionBorderColor(String priority) {
    switch (priority) {
      case 'high':
        return const Color(0xFFFF6B6B).withOpacity(0.3);
      case 'medium':
        return const Color(0xFFFF9A3D).withOpacity(0.3);
      default:
        return const Color(0xFF2D7DD2).withOpacity(0.3);
    }
  }

  Color _getSuggestionIconColor(String priority) {
    switch (priority) {
      case 'high':
        return const Color(0xFFFF6B6B);
      case 'medium':
        return const Color(0xFFFF9A3D);
      default:
        return const Color(0xFF2D7DD2);
    }
  }

  Color _getSuggestionTextColor(String priority) {
    switch (priority) {
      case 'high':
        return const Color(0xFFD63031);
      case 'medium':
        return const Color(0xFFE17055);
      default:
        return const Color(0xFF2D7DD2);
    }
  }
}