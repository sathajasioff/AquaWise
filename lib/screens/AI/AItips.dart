import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:watermeter/services/remote_config_service.dart';
import 'package:watermeter/screens/Home/dashboard_1.dart';
import 'package:watermeter/screens/Profile/profile.dart';

class AIPersonalizationPage extends StatefulWidget {
  const AIPersonalizationPage({super.key});

  @override
  State<AIPersonalizationPage> createState() => _AIPersonalizationPageState();
}

class _AIPersonalizationPageState extends State<AIPersonalizationPage> {
  String? userPersona;
  bool isLoading = true;
  String? errorMessage;
  List<Map<String, String>> tips = [];
  double _simulatedHarvest = 0.0;
  int _selectedIndex = 2;

  final TextEditingController _roofController = TextEditingController();
  String _location = "Colombo";

  @override
  void initState() {
    super.initState();
    _initializePage();
  }

  Future<void> _initializePage() async {
    setState(() => isLoading = true);

    await RemoteConfigService().initialize();

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        errorMessage = 'User not authenticated. Please log in.';
        isLoading = false;
        tips = _getFallbackTips();
      });
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      userPersona = doc.data()?['persona'] ?? 'Casual User';
      await _generateAITips(userPersona!);
    } catch (e) {
      errorMessage = 'Error fetching persona: $e';
      tips = _getFallbackTips();
    }

    setState(() => isLoading = false);
  }

  List<Map<String, String>> _getFallbackTips() => [
        {
          "title": "Short Shower",
          "description": "Reduce shower time to 4 minutes.",
          "label": "easy",
          "saving": "-30L/day"
        },
        {
          "title": "Dishwater Collection",
          "description": "Collect rinse water for plants.",
          "label": "medium",
          "saving": "-10L/day"
        },
      ];

  /// Gemini AI Tip Generation
  Future<void> _generateAITips(String persona) async {
    try {
      final gemini = Gemini.instance;
      final prompt = '''
      You are a water conservation expert. Generate 2-3 personalized water-saving tips for $persona.
      Include: Title, Description, Difficulty, Estimated Savings.
      Format: "Title: Description (Difficulty, Savings)."
      ''';

      final response = await gemini.text(prompt);
      final generatedText = response!.toJson()['output'] ?? '';

      final parsedTips = generatedText
          .split('\n')
          .where((tip) => tip.trim().isNotEmpty)
          .map((tip) {
            try {
              final parts = tip.split(': ');
              final descParts = parts[1].split(' (');
              final meta = descParts[1].replaceAll(')', '').split(', ');
              return {
                'title': parts[0],
                'description': descParts[0],
                'label': meta[0],
                'saving': meta[1],
              };
            } catch (_) {
              return null;
            }
          })
          .whereType<Map<String, String>>()
          .toList();

      setState(() => tips = parsedTips.isNotEmpty ? parsedTips : _getFallbackTips());
    } catch (e) {
      setState(() {
        errorMessage = 'Error generating tips: $e';
        tips = _getFallbackTips();
      });
    }
  }

  /// Rainwater Simulation using OpenWeatherMap API
  Future<void> _simulateHarvest() async {
    try {
      final roofArea = double.tryParse(_roofController.text);
      if (roofArea == null) return;

      final apiKey = Uri.encodeComponent(dotenv.env['OPENWEATHER_API_KEY']!);
      final response = await http.get(Uri.parse(
          'https://api.openweathermap.org/data/2.5/forecast?q=$_location&appid=$apiKey'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rain = (data['list'] as List)
            .fold<double>(0.0, (sum, day) => sum + ((day['rain'] ?? 0.0) as double));
        setState(() => _simulatedHarvest = roofArea * rain * 0.8);
      }
    } catch (e) {
      print('Simulation error: $e');
    }
  }

  void _applyTip(String tipTitle) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastAppliedTip', tipTitle);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Tip "$tipTitle" applied today! ✅')),
    );
  }

  void _onNavItemTapped(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);

    switch (index) {
      case 0:
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardPage()));
        break;
      case 3:
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ProfilePage()));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _personaSelector(screenWidth),
              SizedBox(height: screenWidth * 0.05),
              _aiTips(screenWidth),
              SizedBox(height: screenWidth * 0.05),
              _simulatorCard(screenWidth),
              SizedBox(height: screenWidth * 0.05),
              _footprintCard(screenWidth),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF176ED2),
        unselectedItemColor: Colors.grey[600],
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.water_drop), label: 'Track'),
          BottomNavigationBarItem(icon: Icon(Icons.lightbulb), label: 'Tips'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        onTap: _onNavItemTapped,
      ),
    );
  }

  Widget _personaSelector(double screenWidth) => Container(
        padding: EdgeInsets.all(screenWidth * 0.04),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Your Persona: ${userPersona ?? 'Loading...'}",
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      );

  Widget _aiTips(double screenWidth) {
    if (isLoading) return const Center(child: CircularProgressIndicator());

    return Container(
      padding: EdgeInsets.all(screenWidth * 0.04),
      child: Column(
        children: tips
            .map((tip) => Card(
                  child: ListTile(
                    title: Text(tip['title']!),
                    subtitle: Text("${tip['description']} (${tip['label']} | ${tip['saving']})"),
                    trailing: ElevatedButton(
                        onPressed: () => _applyTip(tip['title']!), child: const Text("Apply Today")),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _simulatorCard(double screenWidth) => Container(
        padding: EdgeInsets.all(screenWidth * 0.04),
        margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF9DF3E0), Color(0xFFA1EAFB)]),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            const Text("Rainwater Harvesting Simulator", style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(
              controller: _roofController,
              decoration: const InputDecoration(labelText: "Roof Area (m²)"),
              keyboardType: TextInputType.number,
            ),
            DropdownButton<String>(
              value: _location,
              items: const [
                DropdownMenuItem(value: "Colombo", child: Text("Colombo")),
                DropdownMenuItem(value: "Kandy", child: Text("Kandy")),
                DropdownMenuItem(value: "Jaffna", child: Text("Jaffna")),
              ],
              onChanged: (v) => setState(() => _location = v!),
            ),
            ElevatedButton(onPressed: _simulateHarvest, child: const Text("Simulate")),
            Text("${_simulatedHarvest.toStringAsFixed(2)} L Estimated Harvest"),
          ],
        ),
      );

  Widget _footprintCard(double screenWidth) => Container(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Column(
          children: const [
            Text("Water Footprint Calculator", style: TextStyle(fontWeight: FontWeight.bold)),
            Text("1 Cup Coffee: 140L"),
            Text("1 Cotton T-Shirt: 2,700L"),
            Text("1 Sheet Paper: 140L"),
          ],
        ),
      );
}
