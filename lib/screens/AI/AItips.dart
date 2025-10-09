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
  bool isGeneratingTips = false;
  String? errorMessage;
  List<Map<String, String>> tips = [];
  double _simulatedHarvest = 0.0;
  int _selectedIndex = 2;
  bool _isSimulating = false;
  bool _geminiInitialized = false;

  final TextEditingController _roofController = TextEditingController();
  String _location = "Colombo";

  @override
  void initState() {
    super.initState();
    _initializePage();
  }

  /// Initialize user persona and AI tips
  Future<void> _initializePage() async {
    setState(() => isLoading = true);

    await RemoteConfigService().initialize();
    await _initializeGemini();

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
      
      if (_geminiInitialized) {
        await _generateAITips(userPersona!);
      } else {
        tips = _getFallbackTips();
        errorMessage = 'AI service not available. Using standard tips.';
      }
    } catch (e) {
      print('Error fetching persona: $e');
      errorMessage = 'Error fetching persona: $e';
      tips = _getFallbackTips();
    }

    setState(() => isLoading = false);
  }

  /// Initialize Gemini AI
  Future<void> _initializeGemini() async {
    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      print('Gemini API Key from env: ${apiKey != null && apiKey.isNotEmpty ? '✓ Loaded' : '✗ Missing'}');
      
      if (apiKey == null || apiKey.isEmpty) {
        print('Error: GEMINI_API_KEY is missing or empty.');
        _geminiInitialized = false;
        return;
      }

      // Validate API key format (should start with AIza)
      if (!apiKey.startsWith('AIza')) {
        print('Error: Invalid Gemini API key format');
        _geminiInitialized = false;
        return;
      }

      // Initialize Gemini
      Gemini.init(apiKey: apiKey);
      _geminiInitialized = true;
      print('Gemini AI initialized successfully');
    } catch (e) {
      print('Error initializing Gemini: $e');
      _geminiInitialized = false;
    }
  }

  /// Default fallback water-saving tips
  List<Map<String, String>> _getFallbackTips() => [
    {
      "title": "Short Shower",
      "description": "Reduce shower time to 4 minutes to save water.",
      "label": "easy",
      "saving": "-30L/day"
    },
    {
      "title": "Fix Leaky Faucets",
      "description": "A dripping faucet can waste up to 20 gallons of water per day.",
      "label": "medium",
      "saving": "-75L/day"
    },
    {
      "title": "Collect Rainwater",
      "description": "Use collected rainwater for gardening and cleaning.",
      "label": "hard",
      "saving": "-100L/week"
    },
  ];

  /// Gemini AI - Generate personalized tips based on persona
  Future<void> _generateAITips(String persona) async {
    if (!_geminiInitialized) {
      print('Gemini not initialized, using fallback tips');
      setState(() => tips = _getFallbackTips());
      return;
    }

    setState(() => isGeneratingTips = true);
    
    try {
      final gemini = Gemini.instance;
      
      // Simple, clean prompt for Gemini
      final prompt = '''
As a water conservation expert, create 3 personalized water-saving tips for a "$persona".

Provide the response in this exact JSON format only:
[
  {
    "title": "Tip 1 title",
    "description": "Tip 1 description",
    "label": "easy",
    "saving": "25L per day"
  },
  {
    "title": "Tip 2 title", 
    "description": "Tip 2 description",
    "label": "medium",
    "saving": "40L per day"
  },
  {
    "title": "Tip 3 title",
    "description": "Tip 3 description",
    "label": "hard", 
    "saving": "60L per day"
  }
]

Make the tips practical and relevant to daily life.
''';

      print("Sending request to Gemini...");
      
      final response = await gemini.text(prompt).timeout(const Duration(seconds: 30));
      final generatedText = response?.output ?? '';

      print("Gemini Response: ${generatedText.isNotEmpty ? '✓ Received' : '✗ Empty'}");

      if (generatedText.isEmpty) {
        print("Empty response from Gemini");
        setState(() => tips = _getFallbackTips());
        return;
      }

      final parsedTips = _parseGeminiResponse(generatedText);
      setState(() => tips = parsedTips.isNotEmpty ? parsedTips : _getFallbackTips());
      
      print("Successfully processed ${tips.length} tips");
      
    } catch (e) {
      print('Error generating tips: $e');
      setState(() {
        errorMessage = 'AI service temporarily unavailable. Using standard water-saving tips.';
        tips = _getFallbackTips();
      });
    } finally {
      setState(() => isGeneratingTips = false);
    }
  }

  /// Parse Gemini AI response
  List<Map<String, String>> _parseGeminiResponse(String response) {
    try {
      // Clean the response
      String cleanResponse = response.replaceAll('```json', '').replaceAll('```', '').trim();
      
      // Find JSON array
      final startIndex = cleanResponse.indexOf('[');
      final endIndex = cleanResponse.lastIndexOf(']');
      
      if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
        final jsonString = cleanResponse.substring(startIndex, endIndex + 1);
        print("Parsing JSON: $jsonString");
        
        final List<dynamic> jsonList = jsonDecode(jsonString);
        final List<Map<String, String>> parsedTips = [];
        
        for (var item in jsonList) {
          try {
            final tip = {
              'title': item['title']?.toString() ?? 'Water Saving Tip',
              'description': item['description']?.toString() ?? 'Practical water conservation method',
              'label': (item['label']?.toString() ?? 'medium').toLowerCase(),
              'saving': item['saving']?.toString() ?? '-25L/day',
            };
            parsedTips.add(tip);
          } catch (e) {
            print('Error parsing individual tip: $e');
          }
        }
        
        return parsedTips;
      }
    } catch (e) {
      print('JSON parsing failed: $e');
    }

    return _getFallbackTips();
  }

  /// Apply a selected tip and store in Firestore
  void _applyTipToFirestore(String tipTitle) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to apply tips')),
      );
      return;
    }

    try {
      // Get the full tip details
      final tip = tips.firstWhere((t) => t['title'] == tipTitle);
      
      // Store in Firestore
      await FirebaseFirestore.instance
          .collection('applied_tips')
          .add({
            'userEmail': user.email,
            'userId': user.uid,
            'tipTitle': tip['title'],
            'tipDescription': tip['description'],
            'tipDifficulty': tip['label'],
            'estimatedSavings': tip['saving'],
            'appliedDate': FieldValue.serverTimestamp(),
            'status': 'active',
            'userPersona': userPersona,
          });

      // Also update SharedPreferences for local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('lastAppliedTip', tipTitle);
      
      // Show success dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('Tip Applied!'),
            ],
          ),
          content: Text('"$tipTitle" has been applied for today! ✅'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      print('Error applying tip: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error applying tip. Please try again.')),
      );
    }
  }

  /// Rainwater Harvesting Simulation using OpenWeatherMap API
  Future<void> _simulateHarvest() async {
    setState(() => _isSimulating = true);
    
    try {
      final roofArea = double.tryParse(_roofController.text);
      if (roofArea == null || roofArea <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid roof area.')),
        );
        return;
      }

      // Get API key from .env safely
      final apiKey = dotenv.env['OPENWEATHER_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        print('Error: OPENWEATHER_API_KEY is missing.');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Weather service unavailable.')),
        );
        return;
      }

      // Fetch 5-day weather forecast data
      final response = await http.get(Uri.parse(
          'https://api.openweathermap.org/data/2.5/forecast?q=$_location&appid=$apiKey&units=metric'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        double totalRain = 0.0;
        for (var entry in data['list']) {
          if (entry['rain'] != null && entry['rain']['3h'] != null) {
            totalRain += (entry['rain']['3h'] as num).toDouble();
          }
        }

        // Calculate estimated harvest (m² × rainfall × 0.8)
        final estimatedHarvest = roofArea * totalRain * 0.8;

        setState(() => _simulatedHarvest = estimatedHarvest);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Estimated Rainwater Harvest: ${estimatedHarvest.toStringAsFixed(2)} L')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Weather data unavailable (${response.statusCode})')),
        );
      }
    } catch (e) {
      print('Simulation error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Simulation service unavailable.')),
      );
    } finally {
      setState(() => _isSimulating = false);
    }
  }

  /// Handle bottom navigation
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

  /// Get color based on difficulty label
  Color _getDifficultyColor(String label) {
    switch (label.toLowerCase()) {
      case 'easy':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(theme, screenWidth),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildPersonaCard(theme, screenWidth),
                    const SizedBox(height: 24),
                    _buildAITipsSection(theme, screenWidth),
                    const SizedBox(height: 24),
                    _buildSimulatorCard(theme, screenWidth),
                    const SizedBox(height: 24),
                    _buildFootprintCard(theme, screenWidth),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(theme),
    );
  }

  /// Header with title and refresh button
  Widget _buildHeader(ThemeData theme, double screenWidth) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, color: Colors.white),
            ),
            const SizedBox(width: 8),
            Text(
              "Water Saving Tips",
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const Spacer(),
            if (!isLoading && _geminiInitialized)
              IconButton(
                onPressed: () => _generateAITips(userPersona!),
                icon: const Icon(Icons.refresh, color: Colors.white),
                tooltip: 'Refresh Tips',
              ),
          ],
        ),
      ),
    );
  }

  /// Persona Card
  Widget _buildPersonaCard(ThemeData theme, double screenWidth) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, color: theme.colorScheme.primary, size: 24),
                const SizedBox(width: 12),
                Text(
                  "Your Water Profile",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (isLoading)
              const LinearProgressIndicator()
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userPersona ?? 'Casual User',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          Text(
                            _geminiInitialized 
                                ? "AI-powered personalized tips"
                                : "Standard water-saving tips",
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      _geminiInitialized ? Icons.auto_awesome : Icons.lightbulb_outline,
                      color: theme.colorScheme.primary
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// AI Tips Section
  Widget _buildAITipsSection(ThemeData theme, double screenWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.lightbulb_outline, color: theme.colorScheme.primary, size: 24),
            const SizedBox(width: 12),
            Text(
              _geminiInitialized ? "AI Personalized Tips" : "Water Saving Tips",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
            const Spacer(),
            if (isGeneratingTips)
              const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          _geminiInitialized 
              ? "Tips for ${userPersona ?? 'your profile'}"
              : "Practical water conservation methods",
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange),
            ),
            child: Row(
              children: [
                Icon(Icons.info, color: Colors.orange[800]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    errorMessage!,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.orange[800],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        if (isLoading)
          _buildLoadingTips()
        else if (tips.isEmpty)
          _buildEmptyTipsState(theme)
        else
          ...tips.map((tip) => _buildTipCard(tip, theme)),
      ],
    );
  }

  /// Loading state for tips
  Widget _buildLoadingTips() {
    return Column(
      children: List.generate(3, (index) => 
        Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: const ListTile(
            leading: CircleAvatar(backgroundColor: Colors.grey),
            title: Text("Loading tips...", style: TextStyle(color: Colors.grey)),
            subtitle: Text("Please wait while we generate recommendations", style: TextStyle(color: Colors.grey)),
          ),
        ),
      ),
    );
  }

  /// Empty tips state
  Widget _buildEmptyTipsState(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.water_drop, size: 64, color: theme.colorScheme.primary.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              "Tips Loading",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "We're preparing your water-saving recommendations",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => _generateAITips(userPersona!),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  /// Individual tip card
  Widget _buildTipCard(Map<String, String> tip, ThemeData theme) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _geminiInitialized ? Icons.auto_awesome : Icons.eco,
                    color: theme.colorScheme.primary,
                    size: 20
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tip['title']!,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tip['description']!,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getDifficultyColor(tip['label']!).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: _getDifficultyColor(tip['label']!).withOpacity(0.3)),
                            ),
                            child: Text(
                              tip['label']!.toUpperCase(),
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: _getDifficultyColor(tip['label']!),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.water_drop, size: 16, color: Colors.blue),
                          const SizedBox(width: 4),
                          Text(
                            tip['saving']!,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => _applyTipToFirestore(tip['title']!),
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(
                  "Apply Today",
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Rainwater Harvesting Simulator
  Widget _buildSimulatorCard(ThemeData theme, double screenWidth) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.cloud, color: theme.colorScheme.primary, size: 24),
                const SizedBox(width: 10),
                Text(
                  "Rainwater Harvesting Simulator",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _roofController,
              decoration: InputDecoration(
                labelText: "Roof Area (m²)",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.square_foot),
                hintText: "Enter your roof area",
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            InputDecorator(
              decoration: InputDecoration(
                labelText: "Location",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.location_on),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _location,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: "Colombo", child: Text("Colombo")),
                    DropdownMenuItem(value: "Kandy", child: Text("Kandy")),
                    DropdownMenuItem(value: "Jaffna", child: Text("Jaffna")),
                  ],
                  onChanged: (v) => setState(() => _location = v!),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: _isSimulating ? null : _simulateHarvest,
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSimulating
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        "Simulate Harvest",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
              ),
            ),
            if (_simulatedHarvest > 0) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.water_drop, color: Colors.blue, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Estimated Harvest",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                          Text(
                            "${_simulatedHarvest.toStringAsFixed(2)} Liters",
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Water Footprint Card
  Widget _buildFootprintCard(ThemeData theme, double screenWidth) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: theme.colorScheme.primary, size: 24),
                const SizedBox(width: 12),
                Text(
                  "Water Footprint Facts",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildFootprintItem("1 Cup Coffee", "140L", Icons.coffee),
            _buildFootprintItem("1 Cotton T-Shirt", "2,700L", Icons.face),
            _buildFootprintItem("1 Sheet Paper", "10L", Icons.description),
            _buildFootprintItem("1 Glass Milk", "200L", Icons.local_drink),
          ],
        ),
      ),
    );
  }

  /// Individual footprint item
  Widget _buildFootprintItem(String item, String amount, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              item,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              amount,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Bottom Navigation Bar
  Widget _buildBottomNavigationBar(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: theme.colorScheme.primary,
        unselectedItemColor: Colors.grey[600],
        selectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500),
        unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w400),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.water_drop_outlined),
            activeIcon: Icon(Icons.water_drop),
            label: 'Track',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.lightbulb_outline),
            activeIcon: Icon(Icons.lightbulb),
            label: 'Tips',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        onTap: _onNavItemTapped,
      ),
    );
  }
}