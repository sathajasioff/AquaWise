import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QuestionnairePage extends StatefulWidget {
  const QuestionnairePage({super.key});

  @override
  State<QuestionnairePage> createState() => _QuestionnairePageState();
}

class _QuestionnairePageState extends State<QuestionnairePage> {
  int _currentStep = 0;
  final Map<int, String> _answers = {};
  String? _selectedOption;
  bool _isLoading = false;
  String? _errorMessage;

  final List<Map<String, dynamic>> _questions = [
    {
      "question": "What’s your main reason for using this app?",
      "options": [
        "To protect the environment",
        "To save money on my water bill",
        "Just curious to see my usage",
        "I want to learn how to save water"
      ]
    },
    {
      "question": "How much do you know about water conservation?",
      "options": [
        "A lot — I already practice it daily",
        "Some — I do small things here and there",
        "Not much — I need more info"
      ]
    },
    {
      "question": "How much time are you willing to spend tracking usage?",
      "options": [
        "I’m fine with detailed tracking and reports",
        "I prefer quick updates and easy inputs",
        "I want the app to do most of the work"
      ]
    },
    {
      "question": "Who are you tracking water usage for?",
      "options": [
        "Myself",
        "My family / roommates",
        "My business / rental property"
      ]
    },
    {
      "question": "Which goal matters most to you?",
      "options": [
        "Reduce wastage to near zero",
        "Lower my bills by a certain percentage",
        "Build a habit of mindful usage",
        "Understand my current usage patterns"
      ]
    },
  ];

  final Map<String, String> _answerToPersona = {
    // Q1
    "To protect the environment": "Eco Warrior",
    "To save money on my water bill": "Budget Saver",
    "Just curious to see my usage": "Casual User",
    "I want to learn how to save water": "Casual User",
    // Q2
    "A lot — I already practice it daily": "Eco Warrior",
    "Some — I do small things here and there": "Budget Saver",
    "Not much — I need more info": "Casual User",
    // Q3
    "I’m fine with detailed tracking and reports": "Eco Warrior",
    "I prefer quick updates and easy inputs": "Budget Saver",
    "I want the app to do most of the work": "Casual User",
    // Q4
    "Myself": "Casual User",
    "My family / roommates": "Family Mode",
    "My business / rental property": "Budget Saver",
    // Q5
    "Reduce wastage to near zero": "Eco Warrior",
    "Lower my bills by a certain percentage": "Budget Saver",
    "Build a habit of mindful usage": "Family Mode",
    "Understand my current usage patterns": "Casual User",
  };

  Future<void> _savePersonaToFirestore(String persona) async {
    final user = FirebaseAuth.instance.currentUser;
    print('User: $user'); // Debug
    if (user == null) {
      print('Error: No authenticated user');
      setState(() {
        _errorMessage = 'User not authenticated. Please log in.';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    bool firestoreSuccess = false;
    try {
      final Map<String, String> stringKeyAnswers = {
        for (var entry in _answers.entries) entry.key.toString(): entry.value
      };
      print('Saving persona: $persona, Answers: $stringKeyAnswers'); // Debug
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'persona': persona,
        'questionnaire_answers': stringKeyAnswers,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      print('Persona saved successfully to Firestore'); // Debug
      firestoreSuccess = true;

      // Cache persona locally (non-blocking for navigation)
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_persona', persona);
        print('Persona cached locally: $persona'); // Debug
      } catch (e) {
        print('Error caching persona locally: $e'); // Debug
        setState(() {
          _errorMessage = 'Profile saved, but failed to cache locally: $e';
        });
      }
    } catch (e, stackTrace) {
      print('Error saving persona to Firestore: $e\nStackTrace: $stackTrace'); // Debug
      setState(() {
        _errorMessage = 'Failed to save your profile: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
      // Navigate even if local caching fails
      if (firestoreSuccess && mounted) {
        print('Navigating to /dashboard1'); // Debug
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Profile saved! Welcome, $persona!",
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    }
  }

  Map<String, dynamic> _calculatePersona() {
    final personaCounts = {
      "Eco Warrior": 0,
      "Budget Saver": 0,
      "Family Mode": 0,
      "Casual User": 0,
    };

    // Log answers for debugging
    print('Collected answers: $_answers');

    _answers.forEach((questionIndex, answer) {
      final persona = _answerToPersona[answer] ?? "Casual User";
      // Weight Q1 and Q5 higher for stronger influence
      int weight = (questionIndex == 0 || questionIndex == 4) ? 4 : 1;
      personaCounts[persona] = (personaCounts[persona] ?? 0) + weight;
      print('Question ${questionIndex + 1}: Answer "$answer" → Persona "$persona" (Weight: $weight)'); // Debug
    });

    // Find the persona with the highest score
    String selectedPersona = "Casual User";
    int maxCount = -1;
    List<String> tiedPersonas = [];

    personaCounts.forEach((persona, count) {
      if (count > maxCount) {
        maxCount = count;
        selectedPersona = persona;
        tiedPersonas = [persona];
      } else if (count == maxCount && count > 0) {
        tiedPersonas.add(persona);
      }
    });

    // Tie-breaker: Prioritize Eco Warrior > Budget Saver > Family Mode > Casual User
    if (tiedPersonas.length > 1) {
      print('Tie detected: $tiedPersonas'); // Debug
      const priority = ["Eco Warrior", "Budget Saver", "Family Mode", "Casual User"];
      for (var persona in priority) {
        if (tiedPersonas.contains(persona)) {
          selectedPersona = persona;
          break;
        }
      }
    }

    print('Final persona: $selectedPersona, Scores: $personaCounts'); // Debug
    return {
      'persona': selectedPersona,
      'scores': personaCounts,
    };
  }

  void _nextStep() {
    if (_selectedOption == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Please select an option",
            style: GoogleFonts.poppins(fontSize: 14),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    _answers[_currentStep] = _selectedOption!;
    setState(() {
      _selectedOption = null;
      if (_currentStep < _questions.length - 1) {
        _currentStep++;
      } else {
        final result = _calculatePersona();
        final persona = result['persona'] as String;
        final personaCounts = result['scores'] as Map<String, int>;
        // Show confirmation dialog with selected answers and scores
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            final screenWidth = MediaQuery.of(context).size.width;
            final answersSummary = _answers.entries
                .map((e) => "Q${e.key + 1}: ${e.value}")
                .join("\n");
            final scoresSummary = personaCounts.entries
                .map((e) => "${e.key}: ${e.value}")
                .join("\n");
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              title: Text(
                "Your AquaWise Profile",
                style: GoogleFonts.poppins(
                  fontSize: screenWidth * 0.05,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "You're a $persona!",
                      style: GoogleFonts.poppins(
                        fontSize: screenWidth * 0.04,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    SizedBox(height: screenWidth * 0.02),
                    Text(
                      "We'll tailor water-saving tips to match your goals.",
                      style: GoogleFonts.poppins(
                        fontSize: screenWidth * 0.035,
                        color: Colors.grey[800],
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: screenWidth * 0.03),
                    Text(
                      "Your Answers:\n$answersSummary",
                      style: GoogleFonts.poppins(
                        fontSize: screenWidth * 0.035,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: screenWidth * 0.03),
                    Text(
                      "Scores:\n$scoresSummary",
                      style: GoogleFonts.poppins(
                        fontSize: screenWidth * 0.035,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {
                      _currentStep = 0;
                      _answers.clear();
                      _selectedOption = null;
                    });
                  },
                  child: Text(
                    "Retake",
                    style: GoogleFonts.poppins(
                      fontSize: screenWidth * 0.035,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () async {
                          Navigator.pop(context);
                          await _savePersonaToFirestore(persona);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF176ED2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  child: Text(
                    "Confirm",
                    style: GoogleFonts.poppins(
                      fontSize: screenWidth * 0.035,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final question = _questions[_currentStep];
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          "AquaWise Questionnaire",
          style: GoogleFonts.poppins(
            fontSize: screenWidth * 0.05,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF176ED2),
        elevation: 2,
        shadowColor: Colors.grey.withOpacity(0.2),
      ),
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.all(screenWidth * 0.05),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LinearProgressIndicator(
                  value: (_currentStep + 1) / _questions.length,
                  backgroundColor: Colors.grey[200],
                  color: const Color(0xFF176ED2),
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(10),
                ),
                SizedBox(height: screenWidth * 0.04),
                Text(
                  "Question ${_currentStep + 1} of ${_questions.length}",
                  style: GoogleFonts.poppins(
                    fontSize: screenWidth * 0.035,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: screenWidth * 0.02),
                Text(
                  question["question"],
                  style: GoogleFonts.poppins(
                    fontSize: screenWidth * 0.05,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: screenWidth * 0.05),
                ...List.generate(
                  question["options"].length,
                  (index) {
                    final option = question["options"][index];
                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: EdgeInsets.symmetric(vertical: screenWidth * 0.015),
                      child: RadioListTile<String>(
                        title: Text(
                          option,
                          style: GoogleFonts.poppins(
                            fontSize: screenWidth * 0.035,
                            color: Colors.black87,
                          ),
                        ),
                        value: option,
                        groupValue: _selectedOption,
                        onChanged: (value) {
                          setState(() {
                            _selectedOption = value;
                          });
                        },
                        activeColor: const Color(0xFF176ED2),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.04,
                          vertical: screenWidth * 0.02,
                        ),
                      ),
                    );
                  },
                ),
                if (_errorMessage != null) ...[
                  SizedBox(height: screenWidth * 0.03),
                  Text(
                    _errorMessage!,
                    style: GoogleFonts.poppins(
                      fontSize: screenWidth * 0.035,
                      color: Colors.red,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _nextStep,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF176ED2),
                      padding: EdgeInsets.symmetric(vertical: screenWidth * 0.035),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: Text(
                      _currentStep == _questions.length - 1 ? "Finish" : "Next",
                      style: GoogleFonts.poppins(
                        fontSize: screenWidth * 0.045,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: Color(0xFF176ED2))),
        ],
      ),
    );
  }
}