import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Color(0xFF1A2B47)),
        title: Text(
          "About AquaWise",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: const Color(0xFF1A2B47),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Header Section with Logo
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2D7DD2), Color(0xFF1A5FA6)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Logo placeholder with professional styling
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.water_drop_outlined,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "AquaWise",
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Smarter Water. Greener Future.",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "Sustainable Water Management",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Introduction Section
            _buildAboutSection(
              icon: Icons.eco_outlined,
              title: "Welcome to AquaWise",
              content: "AquaWise is a sustainability-driven mobile app that empowers individuals and families "
                  "to monitor, manage, and reduce their daily water usage. By blending AI insights, gamification, "
                  "and community engagement, AquaWise helps you make every drop count.",
            ),

            const SizedBox(height: 24),
            _buildAboutSection(
              icon: Icons.flag_outlined,
              title: "Our Mission",
              content: "Our mission is to promote water conservation globally by helping users make small daily "
                  "decisions that lead to big environmental impact — aligning with UN SDG 6: Clean Water and Sanitation.",
              highlightColor: Colors.green,
            ),

            const SizedBox(height: 24),
            _buildFeatureSection(
              title: "What AquaWise Offers",
              features: [
                _FeatureItem(
                  icon: Icons.track_changes_outlined,
                  text: "Real-time water usage tracking",
                  color: Colors.blue,
                ),
                _FeatureItem(
                  icon: Icons.auto_awesome_outlined,
                  text: "Personalized eco-friendly recommendations",
                  color: Colors.purple,
                ),
                _FeatureItem(
                  icon: Icons.emoji_events_outlined,
                  text: "Gamified rewards and challenges",
                  color: Colors.orange,
                ),
                _FeatureItem(
                  icon: Icons.family_restroom_outlined,
                  text: "Family & group dashboards",
                  color: Colors.teal,
                ),
                _FeatureItem(
                  icon: Icons.psychology_outlined,
                  text: "AI-based water-saving insights",
                  color: Colors.indigo,
                ),
                _FeatureItem(
                  icon: Icons.analytics_outlined,
                  text: "Monthly budgeting and goal tracking",
                  color: Colors.red,
                ),
              ],
            ),

            const SizedBox(height: 24),
            _buildAboutSection(
              icon: Icons.history_edu_outlined,
              title: "Our Story",
              content: "AquaWise began as an academic innovation at the Sri Lanka Institute of Information Technology (SLIIT). "
                  "It was designed by students passionate about sustainability and technology. Over time, it evolved into "
                  "a real-world initiative supporting smarter resource management across communities.",
              highlightColor: Colors.brown,
            ),

            const SizedBox(height: 24),
            _buildAboutSection(
              icon: Icons.verified_user_outlined,
              title: "Our Commitment",
              content: "We are committed to transparency, user privacy, and ethical technology. Your data is secure, "
                  "and your conservation journey is yours to own. AquaWise continues to innovate toward a sustainable, "
                  "water-secure world.",
              highlightColor: Colors.blue,
            ),

            const SizedBox(height: 24),
            // Contact Section
            Container(
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
                          Icons.contact_support_outlined,
                          color: Color(0xFFFF9A3D),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "Get In Touch",
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1A2B47),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    height: 1,
                    color: Colors.grey.shade200,
                  ),
                  const SizedBox(height: 20),
                  _buildContactInfo(
                    icon: Icons.email_outlined,
                    title: "Email Us",
                    subtitle: "support@aquawise.app",
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 16),
                  _buildContactInfo(
                    icon: Icons.language_outlined,
                    title: "Visit Website",
                    subtitle: "www.aquawise.app",
                    color: Colors.green,
                  ),
                  const SizedBox(height: 16),
                  _buildContactInfo(
                    icon: Icons.location_on_outlined,
                    title: "Based In",
                    subtitle: "Sri Lanka Institute of Information Technology",
                    color: Colors.red,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Footer
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Text(
                    "AquaWise",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF2D7DD2),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Making Every Drop Count",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 1,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "© 2025 AquaWise | All Rights Reserved",
                    style: GoogleFonts.poppins(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Committed to Sustainable Water Management",
                    style: GoogleFonts.poppins(
                      color: Colors.grey.shade500,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSection({
    required IconData icon,
    required String title,
    required String content,
    Color highlightColor = const Color(0xFF2D7DD2),
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                  color: highlightColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: highlightColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A2B47),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 1,
            color: Colors.grey.shade200,
          ),
          const SizedBox(height: 16),
          Text(
            content,
            style: GoogleFonts.poppins(
              fontSize: 14,
              height: 1.6,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureSection({
    required String title,
    required List<_FeatureItem> features,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                  Icons.featured_play_list_outlined,
                  color: Color(0xFF764BA2),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A2B47),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            height: 1,
            color: Colors.grey.shade200,
          ),
          const SizedBox(height: 20),
          Column(
            children: features.map((feature) => _buildFeatureRow(feature)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(_FeatureItem feature) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: feature.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              feature.icon,
              color: feature.color,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              feature.text,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfo({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A2B47),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FeatureItem {
  final IconData icon;
  final String text;
  final Color color;

  const _FeatureItem({
    required this.icon,
    required this.text,
    required this.color,
  });
}