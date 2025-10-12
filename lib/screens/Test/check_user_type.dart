
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class CheckUserTypePage extends StatefulWidget {
  const CheckUserTypePage({super.key});

  @override
  State<CheckUserTypePage> createState() => _CheckUserTypePageState();
}

class _CheckUserTypePageState extends State<CheckUserTypePage> {
  String? userPersona;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchUserPersona();
  }

  Future<void> _fetchUserPersona() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists) {
          setState(() {
            userPersona = doc.data()?['persona'] ?? 'No persona set';
            isLoading = false;
          });
        } else {
          setState(() {
            userPersona = 'No user data found';
            isLoading = false;
          });
        }
      } catch (e) {
        setState(() {
          errorMessage = 'Error fetching persona: $e';
          isLoading = false;
        });
      }
    } else {
      setState(() {
        errorMessage = 'User not authenticated';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Check User Type',
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
      body: Center(
        child: isLoading
            ? const CircularProgressIndicator()
            : Padding(
                padding: EdgeInsets.all(screenWidth * 0.05),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Your Persona:',
                      style: GoogleFonts.poppins(
                        fontSize: screenWidth * 0.06,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: screenWidth * 0.03),
                    Text(
                      userPersona ?? 'Unknown',
                      style: GoogleFonts.poppins(
                        fontSize: screenWidth * 0.08,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF176ED2),
                      ),
                    ),
                    if (errorMessage != null) ...[
                      SizedBox(height: screenWidth * 0.03),
                      Text(
                        errorMessage!,
                        style: GoogleFonts.poppins(
                          fontSize: screenWidth * 0.04,
                          color: Colors.red,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    SizedBox(height: screenWidth * 0.05),
                    ElevatedButton(
                      onPressed: () => Navigator.pushNamed(context, '/aitips'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF176ED2),
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.06,
                          vertical: screenWidth * 0.035,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: Text(
                        'Go to AI Tips',
                        style: GoogleFonts.poppins(
                          fontSize: screenWidth * 0.045,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}


