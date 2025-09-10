import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


class QuestionnairePage extends StatefulWidget {
  const QuestionnairePage({super.key});

  @override
  State<QuestionnairePage> createState() => _QuestionnairePageState();
}

class _QuestionnairePageState extends State<QuestionnairePage> {
  int _currentStep = 0;
  final Map<int, String> _answers = {};

  // Your questions + options
  final List<Map<String, dynamic>> _questions = [
    {
      "question": "Q1\nWhat’s your main reason for using this app?",
      "options": [
        "To protect the environment",
        "To save money on my water bill",
        "Just curious to see my usage",
        "I want to learn how to save water"
      ]
    },
    {
      "question": "Q2\nHow much do you currently know about water conservation?",
      "options": [
        "A lot — I already practice it daily",
        "Some — I do small things here and there",
        "Not much — I need more info"
      ]
    },
    {
      "question": "Q3\nHow much time are you willing to spend tracking your usage?",
      "options": [
        "I’m fine with detailed tracking and reports",
        "I prefer quick updates and easy inputs",
        "I want the app to do most of the work for me"
      ]
    },
    {
      "question": "Q4\nWho do you want to track water usage for?",
      "options": [
        "Myself",
        "My family / roommates",
        "My business / rental property"
      ]
    },
    {
      "question": "Q5\nWhich of these goals matters most to you?",
      "options": [
        "Reduce wastage to near zero",
        "Lower my bills by a certain percentage",
        "Build a habit of mindful usage",
        "Understand my current usage patterns"
      ]
    },
  ];

  String? _selectedOption;

  void _nextStep() {
    if (_selectedOption != null) {
      _answers[_currentStep] = _selectedOption!;
      setState(() {
        _selectedOption = null; // reset
        if (_currentStep < _questions.length - 1) {
          _currentStep++;
        } else {
          //All questions done → go to Dashboard
          Navigator.pushReplacementNamed(context, '/dashboard1');
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select an option")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final question = _questions[_currentStep];

    return Scaffold(
      appBar: AppBar(
        title: const Text("AquaWise Questionnaire"),
        backgroundColor: const Color(0xFF176ED2),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question text
            Text(
              question["question"],
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Options as RadioListTile
            ...List.generate(
              question["options"].length,
              (index) {
                final option = question["options"][index];
                return RadioListTile<String>(
                  title: Text(option),
                  value: option,
                  groupValue: _selectedOption,
                  onChanged: (value) {
                    setState(() {
                      _selectedOption = value;
                    });
                  },
                );
              },
            ),
            const Spacer(),

            // Next button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _nextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF176ED2),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _currentStep == _questions.length - 1 ? "Finish" : "Next",
                  style: const TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
