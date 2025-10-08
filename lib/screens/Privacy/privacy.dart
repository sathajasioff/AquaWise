import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          "Privacy Policy",
          style: GoogleFonts.poppins(
            color: const Color(0xFF176ED2),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Last Updated: October 2025",
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),

            Text(
              "Your Privacy Matters to Us",
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "At AquaWise, we value your privacy and are committed to protecting your "
              "personal information. This Privacy Policy explains how we collect, use, "
              "and safeguard your data when you use our mobile application.",
              style: GoogleFonts.poppins(fontSize: 15, height: 1.6),
            ),

            const SizedBox(height: 24),
            _sectionTitle("1. Information We Collect"),
            _sectionText(
              "We may collect the following types of information:\n\n"
              "• Personal Information – such as your name, email address, and selected persona.\n"
              "• Usage Data – such as water activity logs (Bathing, Cooking, Cleaning, etc.) "
              "that help us track and analyze your conservation habits.\n"
              "• Device Information – non-identifiable data like app version or system type "
              "used only to improve performance and reliability.",
            ),

            const SizedBox(height: 24),
            _sectionTitle("2. How We Use Your Information"),
            _sectionText(
              "We use the collected data to:\n\n"
              "• Provide personalized insights and water-saving tips.\n"
              "• Track your progress in water conservation challenges.\n"
              "• Enhance user experience and app functionality.\n"
              "• Communicate with you for support or updates.",
            ),

            const SizedBox(height: 24),
            _sectionTitle("3. Data Protection"),
            _sectionText(
              "Your information is securely stored using Google Firebase and encrypted "
              "where possible. We do not sell, rent, or share your personal information "
              "with third parties without your consent.",
            ),

            const SizedBox(height: 24),
            _sectionTitle("4. Your Rights"),
            _sectionText(
              "You can request deletion of your account and associated data at any time. "
              "Please contact our support team at privacy@aquawise.app for data deletion "
              "or privacy-related queries.",
            ),

            const SizedBox(height: 24),
            _sectionTitle("5. Changes to This Policy"),
            _sectionText(
              "We may update this Privacy Policy from time to time. "
              "All updates will be reflected in this page with the revised effective date.",
            ),

            const SizedBox(height: 24),
            _sectionTitle("6. Contact Us"),
            _sectionText(
              "If you have any questions about this Privacy Policy or how we handle your data, "
              "please reach out at:\n\n"
              "📧 support@aquawise.app\n🌐 www.aquawise.app",
            ),

            const SizedBox(height: 30),
            Center(
              child: Text(
                "© 2025 AquaWise | All Rights Reserved",
                style: GoogleFonts.poppins(
                  color: Colors.grey[600],
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 Helper widgets for cleaner UI
  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF176ED2),
      ),
    );
  }

  Widget _sectionText(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 14,
        height: 1.6,
        color: Colors.black87,
      ),
    );
  }
}
