import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          "AquaWise",
          style: GoogleFonts.poppins(
            fontSize: screenWidth * 0.055,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF176ED2),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person, color: Colors.black87),
            onPressed: () {
              Navigator.pushNamed(context, '/profilepage');
            },
          ),
          SizedBox(width: screenWidth * 0.03),
          const Icon(Icons.notifications_none, color: Colors.black87),
          SizedBox(width: screenWidth * 0.03),
          const Icon(Icons.settings, color: Colors.black87),
          SizedBox(width: screenWidth * 0.04),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Column(
          children: [
            // 🔹 Today's Water Usage Card
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(screenWidth * 0.05),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00B4DB), Color(0xFF0083B0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    "Today's Water Usage",
                    style: GoogleFonts.poppins(
                      fontSize: screenWidth * 0.045,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: screenWidth * 0.025),
                  Text(
                    "245L",
                    style: GoogleFonts.poppins(
                      fontSize: screenWidth * 0.09,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: screenWidth * 0.04),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _usageButton("-10L", screenWidth),
                      SizedBox(width: screenWidth * 0.025),
                      _usageButton("+10L", screenWidth),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: screenWidth * 0.05),

            // 🔹 Daily Goal Progress
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(screenWidth * 0.05),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
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
                      Text(
                        "Daily Goal Progress",
                        style: GoogleFonts.poppins(
                          fontSize: screenWidth * 0.04,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "Over Target",
                          style: GoogleFonts.poppins(
                            fontSize: screenWidth * 0.03,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: screenWidth * 0.025),
                  LinearProgressIndicator(
                    value: 245 / 200, // used/goal
                    backgroundColor: Colors.grey[200],
                    color: const Color(0xFF176ED2),
                    minHeight: 10,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  SizedBox(height: screenWidth * 0.02),
                  Text(
                    "Used: 245L   |   Goal: 200L",
                    style: GoogleFonts.poppins(
                      fontSize: screenWidth * 0.032,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: screenWidth * 0.05),

            // 🔹 Weekly Stats
            Row(
              children: [
                Expanded(
                  child: _statCard("This Week", "1680L", Colors.green, screenWidth),
                ),
                SizedBox(width: screenWidth * 0.03),
                Expanded(
                  child: _statCard("Weekly Goal", "1400L", Colors.orange, screenWidth),
                ),
              ],
            ),
            SizedBox(height: screenWidth * 0.05),

            // 🔹 AI Tips Card
            _buildAITipsCard(theme, screenWidth, context),
          ],
        ),
      ),
    );
  }

  Widget _usageButton(String label, double screenWidth) {
    return ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: screenWidth * 0.03),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: screenWidth * 0.04,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _statCard(String title, String value, Color color, double screenWidth) {
    return Container(
      padding: EdgeInsets.all(screenWidth * 0.04),
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
              fontSize: screenWidth * 0.035,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: screenWidth * 0.02),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: screenWidth * 0.055,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAITipsCard(ThemeData theme, double screenWidth, BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/aitips');
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(screenWidth * 0.04),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF176ED2), Color(0xFF4A90E2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              Icons.psychology,
              color: Colors.white,
              size: screenWidth * 0.07,
            ),
            SizedBox(width: screenWidth * 0.03),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI-Powered Tips',
                    style: GoogleFonts.poppins(
                      fontSize: screenWidth * 0.04,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: screenWidth * 0.015),
                  Text(
                    'Get personalized water-saving tips tailored to your usage.',
                    style: GoogleFonts.poppins(
                      fontSize: screenWidth * 0.03,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white,
              size: screenWidth * 0.05,
            ),
          ],
        ),
      ),
    );
  }
}