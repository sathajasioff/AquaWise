import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          "About AquaWise",
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
            // --- Logo & Heading ---
            Center(
              child: Column(
                children: [
                  Image.asset(
                    'assets/images/AquawiseLogo.png', // ✅ Ensure this exists
                    height: 100,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Smarter Water. Greener Future.",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // --- Intro paragraph ---
            Text(
              "AquaWise is a sustainability-driven mobile app that empowers individuals and families "
              "to monitor, manage, and reduce their daily water usage. By blending AI insights, gamification, "
              "and community engagement, AquaWise helps you make every drop count.",
              style: GoogleFonts.poppins(fontSize: 15, height: 1.6),
            ),

            const SizedBox(height: 24),
            _sectionTitle("🌍 Mission"),
            _sectionText(
              "Our mission is to promote water conservation globally by helping users make small daily "
              "decisions that lead to big environmental impact — aligning with UN SDG 6: Clean Water and Sanitation.",
            ),

            const SizedBox(height: 24),
            _sectionTitle("💧 What AquaWise Offers"),
            _sectionText(
              "• Real-time water usage tracking\n"
              "• Personalized eco-friendly recommendations\n"
              "• Gamified rewards and challenges\n"
              "• Family & group dashboards\n"
              "• AI-based water-saving insights\n"
              "• Monthly budgeting and goal tracking",
            ),

            const SizedBox(height: 24),
            _sectionTitle("💡 Our Story"),
            _sectionText(
              "AquaWise began as an academic innovation at the Sri Lanka Institute of Information Technology (SLIIT). "
              "It was designed by students passionate about sustainability and technology. Over time, it evolved into "
              "a real-world initiative supporting smarter resource management across communities.",
            ),

            const SizedBox(height: 24),
            _sectionTitle("🤝 Our Commitment"),
            _sectionText(
              "We are committed to transparency, user privacy, and ethical technology. Your data is secure, "
              "and your conservation journey is yours to own. AquaWise continues to innovate toward a sustainable, "
              "water-secure world.",
            ),

            const SizedBox(height: 24),
            _sectionTitle("📞 Contact Us"),
            _sectionText(
              "We’d love to hear from you!\n\n"
              "📧 support@aquawise.app\n"
              "🌐 www.aquawise.app",
            ),

            const SizedBox(height: 40),
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

  // --- Helper widgets for cleaner structure ---
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
