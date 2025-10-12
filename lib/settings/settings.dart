import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:watermeter/controllers/theme_controller.dart';
import '../screens/Profile/edit_profile_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Provider.of<ThemeController>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      appBar: AppBar(
        title: Text(
          "Settings",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: const Color(0xFF1A2B47),
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Color(0xFF1A2B47)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 Appearance Section
            Text(
              "Appearance",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A2B47),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
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
                          Icons.palette_outlined,
                          color: Color(0xFFFF9A3D),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Theme Preference",
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1A2B47),
                              ),
                            ),
                            Text(
                              "Choose your preferred app theme",
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _themeToString(themeController.themeMode),
                        isExpanded: true,
                        icon: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2D7DD2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_drop_down,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        // FIX: Add dropdown menu properties to prevent overflow
                        dropdownColor: Colors.white,
                        elevation: 4,
                        borderRadius: BorderRadius.circular(12),
                        itemHeight: 70, // Fixed height for each dropdown item
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: const Color(0xFF1A2B47),
                        ),
                        items: [
                          _buildThemeOption(
                            'light',
                            Icons.light_mode_outlined,
                            "Light Mode",
                            "Bright and clean appearance",
                          ),
                          _buildThemeOption(
                            'dark',
                            Icons.dark_mode_outlined,
                            "Dark Mode",
                            "Easy on the eyes in low light",
                          ),
                          _buildThemeOption(
                            'system',
                            Icons.settings_suggest_outlined,
                            "System Default",
                            "Follow your device settings",
                          ),
                        ],
                        onChanged: (val) async {
                          if (val == null) return;
                          await themeController.updateTheme(val);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "Theme changed to ${val == 'system' ? 'system default' : val}",
                                  style: GoogleFonts.poppins(),
                                ),
                                backgroundColor: Colors.green,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // 🔹 Account & Preferences Section
            Text(
              "Account & Preferences",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A2B47),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            Container(
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
              ),
              child: Column(
                children: [
                  _buildSettingItem(
                    icon: Icons.person_outline,
                    iconColor: Color(0xFF2D7DD2),
                    title: "Edit Profile",
                    subtitle: "Update your personal information",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EditProfilePage(),
                        ),
                      );
                    },
                  ),
                  _buildDivider(),
                  _buildSettingItem(
                    icon: Icons.privacy_tip_outlined,
                    iconColor: Color(0xFF00B894),
                    title: "Privacy Policy",
                    subtitle: "Learn about our data practices",
                    onTap: () {
                      Navigator.pushNamed(context, '/privacy_policy');
                    },
                  ),
                  _buildDivider(),
                  _buildSettingItem(
                    icon: Icons.help_outline,
                    iconColor: Color(0xFFFF9A3D),
                    title: "Help & Support",
                    subtitle: "Get help using AquaWise",
                    onTap: () {
                      Navigator.pushNamed(context, '/help');
                    },
                  ),
                  _buildDivider(),
                  _buildSettingItem(
                    icon: Icons.info_outline,
                    iconColor: Color(0xFF764BA2),
                    title: "About AquaWise",
                    subtitle: "Learn more about our app",
                    onTap: () {
                      Navigator.pushNamed(context, '/about');
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // 🔹 App Information Section
            Text(
              "App Information",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A2B47),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
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
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF667EEA).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.phone_iphone_outlined,
                      color: Color(0xFF667EEA),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "App Version",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1A2B47),
                          ),
                        ),
                        Text(
                          "Stay updated with the latest features",
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D7DD2).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "v1.0.0",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF2D7DD2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // 🔹 Footer
            Center(
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
                  const SizedBox(height: 4),
                  Text(
                    "Smart Water Management",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "© 2025 AquaWise. All rights reserved. | ProGrow",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey.shade500,
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

  // 🧩 Helper: Setting Tile
  Widget _buildSettingItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF1A2B47),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade600),
      ),
      trailing: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.arrow_forward_ios_rounded,
          color: Colors.grey.shade600,
          size: 14,
        ),
      ),
    );
  }

  // 🧩 Helper: Custom Divider
  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(height: 1, color: Colors.grey.shade200),
    );
  }

  // 🧩 Helper: Theme Option
  DropdownMenuItem<String> _buildThemeOption(
    String value,
    IconData icon,
    String text,
    String description,
  ) {
    return DropdownMenuItem(
      value: value,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A2B47),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🧩 Helper: Convert ThemeMode → String
  static String _themeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      default:
        return 'system';
    }
  }
}
