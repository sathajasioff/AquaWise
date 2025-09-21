import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_gemini/flutter_gemini.dart';

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
  int _selectedIndex = 2; // Default to Tips (this page)

  @override
  void initState() {
    super.initState();
    _fetchUserPersonaAndTips();
  }

  Future<void> _fetchUserPersonaAndTips() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final user = FirebaseAuth.instance.currentUser;
    print('User: $user'); // Debug
    if (user == null) {
      print('Error: No authenticated user');
      setState(() {
        errorMessage = 'User not authenticated. Please log in.';
        isLoading = false;
        tips = _getFallbackTips();
      });
      return;
    }

    try {
      print('Fetching Firestore doc for user: ${user.uid}');
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      print('Doc exists: ${doc.exists}, Data: ${doc.data()}'); // Debug
      if (!doc.exists) {
        setState(() {
          errorMessage = 'No user data found in Firestore.';
          userPersona = 'Casual User';
          isLoading = false;
          tips = _getFallbackTips();
        });
        return;
      }

      final data = doc.data();
      if (data == null || !data.containsKey('persona')) {
        setState(() {
          errorMessage = 'Persona not set in Firestore.';
          userPersona = 'Casual User';
          isLoading = false;
          tips = _getFallbackTips();
        });
        return;
      }

      setState(() {
        userPersona = data['persona'] as String;
        isLoading = false;
      });

      await _generateAITips(userPersona!);
    } catch (e, stackTrace) {
      print('Error fetching persona: $e\nStackTrace: $stackTrace'); // Debug
      setState(() {
        errorMessage = 'Error fetching persona: $e';
        userPersona = 'Casual User';
        isLoading = false;
        tips = _getFallbackTips();
      });
    }
  }

  Future<void> _generateAITips(String persona) async {
    try {
      final gemini = Gemini.instance;
      final prompt = '''
      You are a water conservation expert. Generate 2-3 practical, personalized water-saving tips for a $persona.
      Each tip should include: Title, Description, Difficulty (easy/medium), Estimated savings (e.g., -20L/day).
      Format each tip as: "Title: Description (Difficulty, Savings)."
      Focus on household tips relevant to their goal (e.g., Eco Warrior: environmental impact, Budget Saver: cost savings, Family Mode: family habits, Casual User: simple actions).
      ''';
      print('Calling Gemini with persona: $persona'); // Debug
      final response = await gemini.text(prompt); // Use text method
      print('Raw Gemini response: $response'); // Debug
      print('Response JSON: ${response?.toJson()}'); // Debug JSON structure

      // Handle response carefully
      if (response == null) {
        throw Exception('Gemini response is null');
      }

      // Try accessing possible fields (output, content, or text)
      String generatedText = '';
      if (response.toJson().containsKey('output')) {
        generatedText = response.toJson()['output'] ?? '';
      } else if (response.toJson().containsKey('content')) {
        generatedText = response.toJson()['content'] ?? '';
      } else if (response.toJson().containsKey('text')) {
        generatedText = response.toJson()['text'] ?? '';
      } else {
        throw Exception('No valid text field found in response');
      }

      if (generatedText.isEmpty) {
        throw Exception('Generated text is empty');
      }
      print('Generated tips: $generatedText'); // Debug

      final parsedTips = generatedText
          .split('\n')
          .where((tip) => tip.trim().isNotEmpty)
          .map((tip) {
            try {
              final parts = tip.split(': ');
              if (parts.length < 2) return null;
              final descParts = parts[1].split(' (');
              if (descParts.length < 2) return null;
              final meta = descParts[1].replaceAll(')', '').split(', ');
              if (meta.length < 2) return null;
              return {
                'title': parts[0],
                'description': descParts[0],
                'label': meta[0],
                'saving': meta[1],
              };
            } catch (e) {
              print('Error parsing tip: $tip, Error: $e'); // Debug
              return null;
            }
          })
          .where((tip) => tip != null)
          .cast<Map<String, String>>()
          .toList();

      setState(() {
        tips = parsedTips.isNotEmpty ? parsedTips : _getFallbackTips();
      });
    } catch (e, stackTrace) {
      print('Error generating tips with Gemini: $e\nStackTrace: $stackTrace'); // Debug
      setState(() {
        errorMessage = errorMessage != null
            ? '$errorMessage\nError generating tips: $e'
            : 'Error generating tips: $e';
        tips = _getFallbackTips();
      });
    }
  }

  List<Map<String, String>> _getFallbackTips() {
    return [
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
  }

  void _onNavItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Add navigation logic here (e.g., Navigator.push to other pages)
    switch (index) {
      case 0:
        print('dashboard1'); // Replace with actual navigation
        break;
      case 1:
        print('Navigate to Track'); // Replace with actual navigation
        break;
      case 2:
        print('Stay on Tips'); // Already on this page
        break;
      case 3:
        print('Navigate to Profile'); // Replace with actual navigation
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _personaSelector(theme, screenWidth),
              SizedBox(height: screenWidth * 0.05),
              _aiTips(theme, screenWidth),
              if (errorMessage != null) ...[
                SizedBox(height: screenWidth * 0.03),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                  child: Text(
                    errorMessage!,
                    style: GoogleFonts.poppins(
                      fontSize: screenWidth * 0.035,
                      color: Colors.red,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              SizedBox(height: screenWidth * 0.05),
              _simulatorCard(theme, screenWidth),
              SizedBox(height: screenWidth * 0.05),
              _footprintCard(theme, screenWidth),
              SizedBox(height: screenWidth * 0.05),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                child: Text(
                  "Learning Hub",
                  style: GoogleFonts.poppins(
                    fontSize: screenWidth * 0.045,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              SizedBox(height: screenWidth * 0.04),
              _learningCard(
                theme: theme,
                title: "The Hidden Water in Your Food",
                category: "Education",
                desc: "Discover the virtual water footprint of everyday items",
                time: "3 min read",
              ),
              _learningCard(
                theme: theme,
                title: "Greywater Systems 101",
                category: "DIY",
                desc: "Simple ways to reuse household water",
                time: "5 min read",
              ),
              SizedBox(height: screenWidth * 0.075),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.water_drop),
            label: 'Track',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.lightbulb),
            label: 'Tips',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF176ED2),
        unselectedItemColor: Colors.grey[600],
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        elevation: 8,
        onTap: _onNavItemTapped,
      ),
    );
  }

  Widget _personaSelector(ThemeData theme, double screenWidth) {
    return Container(
      padding: EdgeInsets.fromLTRB(screenWidth * 0.04, 24, screenWidth * 0.04, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology, color: const Color(0xFF176ED2), size: screenWidth * 0.07),
              SizedBox(width: screenWidth * 0.02),
              Text(
                "AI Personalization",
                style: GoogleFonts.poppins(
                  fontSize: screenWidth * 0.05,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: screenWidth * 0.05),
          Text(
            "Your Persona: ${userPersona ?? 'Loading...'}",
            style: GoogleFonts.poppins(
              fontSize: screenWidth * 0.04,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _aiTips(ThemeData theme, double screenWidth) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF176ED2), Color(0xFF2A80E5)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "AI-Powered Tips for $userPersona",
            style: GoogleFonts.poppins(
              fontSize: screenWidth * 0.045,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          SizedBox(height: screenWidth * 0.04),
          ...tips.map((tip) => _tipCard(
                theme: theme,
                title: tip['title']!,
                label: tip['label']!,
                saving: tip['saving']!,
                description: tip['description']!,
              )),
        ],
      ),
    );
  }

  Widget _tipCard({
    required ThemeData theme,
    required String title,
    required String label,
    required String saving,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.water_drop_outlined, color: theme.primaryColor, size: 24),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "$label | $saving",
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.green.shade800,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            description,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey[800],
              height: 1.5,
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              _buildActionButton(
                text: "Apply Today",
                color: Colors.green.shade600,
                onPressed: () {},
              ),
              SizedBox(width: 12),
              _buildActionButton(
                text: "Learn More",
                color: Colors.grey.shade600,
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String text,
    required Color color,
    required VoidCallback onPressed,
    double? width,
  }) {
    return SizedBox(
      width: width,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _simulatorCard(ThemeData theme, double screenWidth) {
    return Container(
      padding: EdgeInsets.all(screenWidth * 0.04),
      margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF9DF3E0), Color(0xFFA1EAFB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            "Rainwater Harvesting Simulator",
            style: GoogleFonts.poppins(
              fontSize: screenWidth * 0.04,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: screenWidth * 0.03),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    labelText: "Roof Area (m²)",
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              SizedBox(width: screenWidth * 0.03),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: "Colombo",
                  decoration: InputDecoration(
                    labelText: "Location",
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  items: const [
                    DropdownMenuItem(value: "Colombo", child: Text("Colombo")),
                    DropdownMenuItem(value: "Kandy", child: Text("Kandy")),
                    DropdownMenuItem(value: "Jaffna", child: Text("Jaffna")),
                  ],
                  onChanged: (value) {},
                ),
              ),
            ],
          ),
          SizedBox(height: screenWidth * 0.04),
          Text(
            "120L",
            style: GoogleFonts.poppins(
              fontSize: screenWidth * 0.06,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Text(
            "Estimated weekly harvest",
            style: GoogleFonts.poppins(
              fontSize: screenWidth * 0.035,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: screenWidth * 0.03),
          Text(
            "Perfect for garden watering\nCould replace 96L of tap water\nBased on seasonal rainfall in Colombo",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: screenWidth * 0.03,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
          SizedBox(height: screenWidth * 0.03),
          _buildActionButton(
            text: "Get Setup Guide",
            color: Colors.green.shade600,
            onPressed: () {},
            width: screenWidth * 0.4,
          ),
        ],
      ),
    );
  }

  Widget _footprintCard(ThemeData theme, double screenWidth) {
    return Container(
      padding: EdgeInsets.all(screenWidth * 0.04),
      margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Water Footprint Calculator",
            style: GoogleFonts.poppins(
              fontSize: screenWidth * 0.04,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: screenWidth * 0.03),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
              _FootprintItem("1 Cup Coffee", "140L"),
              _FootprintItem("1 Cotton T-Shirt", "2,700L"),
              _FootprintItem("1 Sheet Paper", "140L"),
            ],
          ),
          SizedBox(height: screenWidth * 0.04),
          Center(
            child: _buildActionButton(
              text: "Calculate My Footprint",
              color: const Color(0xFF176ED2),
              onPressed: () {},
              width: screenWidth * 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _learningCard({
    required ThemeData theme,
    required String title,
    required String category,
    required String desc,
    required String time,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8),
          Text(
            desc,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  category,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey[800],
                  ),
                ),
              ),
              const Spacer(),
              Text(
                time,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.green.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FootprintItem extends StatelessWidget {
  final String label;
  final String value;

  const _FootprintItem(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}