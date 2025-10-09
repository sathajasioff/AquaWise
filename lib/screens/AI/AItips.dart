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
import 'package:watermeter/widgets/dashboard_navbar.dart'; // Import your custom navbar

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
  int _selectedIndex = 2; // Set to 2 for Tips page
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
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle, color: Colors.green, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                'Tip Applied!',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A2B47),
                ),
              ),
            ],
          ),
          content: Text(
            '"$tipTitle" has been applied for today! ✅',
            style: GoogleFonts.poppins(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'OK',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF2D7DD2),
                ),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      print('Error applying tip: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error applying tip. Please try again.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
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
          SnackBar(
            content: Text('Please enter a valid roof area.'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        return;
      }

      // Get API key from .env safely
      final apiKey = dotenv.env['OPENWEATHER_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        print('Error: OPENWEATHER_API_KEY is missing.');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Weather service unavailable.'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
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
            content: Text('Estimated Rainwater Harvest: ${estimatedHarvest.toStringAsFixed(2)} L'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Weather data unavailable (${response.statusCode})'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      print('Simulation error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Simulation service unavailable.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
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
      // Add other cases as needed for your navigation structure
    }
  }

  /// Get color based on difficulty label
  Color _getDifficultyColor(String label) {
    switch (label.toLowerCase()) {
      case 'easy':
        return const Color(0xFF00B894);
      case 'medium':
        return const Color(0xFFFF9A3D);
      case 'hard':
        return const Color(0xFFFF6B6B);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildPersonaCard(),
                    const SizedBox(height: 20),
                    _buildAITipsSection(),
                    const SizedBox(height: 20),
                    _buildSimulatorCard(),
                    const SizedBox(height: 20),
                    _buildFootprintCard(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // REPLACED: Using your custom DashboardNavBar instead of the built-in BottomNavigationBar
      bottomNavigationBar: DashboardNavBar(
        currentIndex: _selectedIndex,
        onTap: _onNavItemTapped,
      ),
    );
  }

  /// Header with title and refresh button
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2D7DD2), Color(0xFF1A5FA6)],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "AI Water Saving Tips",
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Personalized conservation strategies",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            if (!isLoading && _geminiInitialized)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: () => _generateAITips(userPersona!),
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                  tooltip: 'Refresh Tips',
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Persona Card
  Widget _buildPersonaCard() {
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D7DD2).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: Color(0xFF2D7DD2),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "Your Water Profile",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A2B47),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (isLoading)
            const LinearProgressIndicator(
              color: Color(0xFF2D7DD2),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F7FF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF2D7DD2).withOpacity(0.3)),
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
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF2D7DD2),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _geminiInitialized 
                              ? "AI-powered personalized tips"
                              : "Standard water-saving tips",
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _geminiInitialized 
                          ? const Color(0xFF764BA2).withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _geminiInitialized ? Icons.auto_awesome : Icons.lightbulb_outline,
                      color: _geminiInitialized ? const Color(0xFF764BA2) : Colors.grey,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// AI Tips Section
  Widget _buildAITipsSection() {
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9A3D).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.lightbulb_outline,
                  color: Color(0xFFFF9A3D),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _geminiInitialized ? "AI Personalized Tips" : "Water Saving Tips",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A2B47),
                  ),
                ),
              ),
              if (isGeneratingTips)
                const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2D7DD2)),
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
              color: Colors.grey.shade600,
            ),
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      errorMessage!,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          if (isLoading)
            _buildLoadingTips()
          else if (tips.isEmpty)
            _buildEmptyTipsState()
          else
            ...tips.map((tip) => _buildTipCard(tip)),
        ],
      ),
    );
  }

  /// Loading state for tips
  Widget _buildLoadingTips() {
    return Column(
      children: List.generate(3, (index) => 
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 120,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Empty tips state
  Widget _buildEmptyTipsState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.water_drop_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            "Tips Loading",
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "We're preparing your water-saving recommendations",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => _generateAITips(userPersona!),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2D7DD2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              'Try Again',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Individual tip card
  Widget _buildTipCard(Map<String, String> tip) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _geminiInitialized 
                      ? const Color(0xFF764BA2).withOpacity(0.1)
                      : const Color(0xFF2D7DD2).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _geminiInitialized ? Icons.auto_awesome : Icons.eco,
                  color: _geminiInitialized ? const Color(0xFF764BA2) : const Color(0xFF2D7DD2),
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tip['title']!,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A2B47),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      tip['description']!,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getDifficultyColor(tip['label']!).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: _getDifficultyColor(tip['label']!).withOpacity(0.3)),
                          ),
                          child: Text(
                            tip['label']!.toUpperCase(),
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _getDifficultyColor(tip['label']!),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Row(
                          children: [
                            Icon(Icons.water_drop, size: 16, color: const Color(0xFF2D7DD2)),
                            const SizedBox(width: 4),
                            Text(
                              tip['saving']!,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF2D7DD2),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _applyTipToFirestore(tip['title']!),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D7DD2),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
              ),
              child: Text(
                "Apply Today",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Rainwater Harvesting Simulator
  Widget _buildSimulatorCard() {
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF00B894).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.cloud_outlined,
                  color: Color(0xFF00B894),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "Rainwater Harvesting Simulator",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A2B47),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _roofController,
            decoration: InputDecoration(
              labelText: "Roof Area (m²)",
              labelStyle: GoogleFonts.poppins(color: const Color.fromARGB(255, 152, 87, 87)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF2D7DD2), width: 2),
              ),
              prefixIcon: const Icon(Icons.square_foot, color: Color(0xFF2D7DD2)),
              hintText: "Enter your roof area",
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _location,
                isExpanded: true,
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D7DD2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_drop_down, color: Colors.white, size: 20),
                ),
                items: const [
                  DropdownMenuItem(value: "Colombo", child: Text("Colombo")),
                  DropdownMenuItem(value: "Kandy", child: Text("Kandy")),
                  DropdownMenuItem(value: "Jaffna", child: Text("Jaffna")),
                ],
                onChanged: (v) => setState(() => _location = v!),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _isSimulating ? null : _simulateHarvest,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D7DD2),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: _isSimulating
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.play_arrow_rounded, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          "Simulate Harvest",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          if (_simulatedHarvest > 0) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF00B894), Color(0xFF00A085)],
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
                    child: const Icon(Icons.water_drop, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Estimated Harvest",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        Text(
                          "${_simulatedHarvest.toStringAsFixed(2)} Liters",
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
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
    );
  }

  /// Water Footprint Card
  Widget _buildFootprintCard() {
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF764BA2).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.analytics_outlined,
                  color: Color(0xFF764BA2),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "Water Footprint Facts",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A2B47),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildFootprintItem("1 Cup Coffee", "140L", Icons.coffee),
          _buildFootprintItem("1 Cotton T-Shirt", "2,700L", Icons.face_retouching_natural),
          _buildFootprintItem("1 Sheet Paper", "10L", Icons.description),
          _buildFootprintItem("1 Glass Milk", "200L", Icons.local_drink),
        ],
      ),
    );
  }

  /// Individual footprint item
  Widget _buildFootprintItem(String item, String amount, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF2D7DD2).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF2D7DD2), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              item,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1A2B47),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF2D7DD2).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              amount,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF2D7DD2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}