import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:watermeter/screens/Profile/edit_profile_page.dart';
import '../../controllers/profile_controller.dart';
import '../../models/usage_model.dart';
import '../../widgets/dashboard_navbar.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final User? user = FirebaseAuth.instance.currentUser;
  final ProfileController _controller = ProfileController();
  Map<String, dynamic>? userData;
  int _selectedIndex = 1;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user!.uid)
          .get();
      if (doc.exists) {
        setState(() {
          userData = doc.data();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = userData?['username'] ?? user?.displayName ?? "User";
    final email = user?.email ?? "No Email";
    final persona = userData?['persona'] ?? "Casual User";

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        title: Text(
          "Profile",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF176ED2),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: user == null
          ? Center(
              child: Text(
                "No user logged in",
                style: GoogleFonts.poppins(fontSize: 16),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  // 🔹 User Info Card
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: const Color(0xFF176ED2),
                            child: Text(
                              name[0].toUpperCase(),
                              style: const TextStyle(
                                fontSize: 40,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            name,
                            style: GoogleFonts.poppins(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            email,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF176ED2).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              persona,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: const Color(0xFF176ED2),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),

                  // 🔹 Action Buttons
                  _actionButton(
                    label: "Edit Profile",
                    icon: Icons.edit,
                    color: Colors.blueAccent,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EditProfilePage(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  _actionButton(
                    label: "Change Password",
                    icon: Icons.lock,
                    color: Colors.orangeAccent,
                    onTap: () async {
                      if (user?.email != null) {
                        await FirebaseAuth.instance.sendPasswordResetEmail(
                          email: user!.email!,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "Password reset link sent to your email",
                            ),
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  _actionButton(
                    label: "Logout",
                    icon: Icons.logout,
                    color: Colors.redAccent,
                    onTap: () async {
                      await FirebaseAuth.instance.signOut();
                      if (context.mounted) {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/login',
                          (route) => false,
                        );
                      }
                    },
                  ),

                  const SizedBox(height: 25),

                  // 🔹 Account Summary
                  Card(
                    color: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Row(
                            children: const [
                              Icon(
                                Icons.info_outline,
                                color: Colors.blueAccent,
                              ),
                              SizedBox(width: 10),
                              Text(
                                "Account Summary",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 20),
                          // _infoRow("User ID", user!.uid),
                          _infoRow("User Type", persona),
                          _infoRow(
                            "Email Verified",
                            user!.emailVerified ? "Yes" : "No",
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // 💧 NEW SECTION: Water Usage History
                  _buildWaterUsageHistory(),
                ],
              ),
            ),
      bottomNavigationBar: DashboardNavBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
      ),
    );
  }

  Widget _buildWaterUsageHistory() {
    return StreamBuilder<List<WaterUsage>>(
      stream: _controller.getUserUsageHistory(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final logs = snapshot.data!;
        if (logs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              "No water usage history yet.",
              style: GoogleFonts.poppins(color: Colors.grey[700]),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Water Usage History",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            ...logs.map(
              (log) => Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 1,
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  leading: const Icon(
                    Icons.water_drop,
                    color: Colors.blueAccent,
                  ),
                  title: Text(
                    "${log.activity} - ${log.liters.toStringAsFixed(1)} L",
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    log.date.toString().split(".")[0].replaceAll("T", "  "),
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: Icon(icon, color: Colors.white),
        label: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[700]),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
