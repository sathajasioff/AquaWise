import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final User? user = FirebaseAuth.instance.currentUser;
  Map<String, dynamic>? userData;

  // @override
  // void initState() {
  //   super.initState();
  //   _loadUserData();
  // }

  // Future<void> _loadUserData() async {
  //   if (user != null) {
  //     final doc = await FirebaseFirestore.instance
  //         .collection("users")
  //         .doc(user!.uid)
  //         .get();
  //     if (doc.exists) {
  //       setState(() {
  //         userData = doc.data();
  //       });
  //     }
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          "Profile",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF176ED2),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
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
                  // 🔹 Profile Avatar
                  const CircleAvatar(
                    radius: 50,
                    backgroundColor: Color(0xFF176ED2),
                    child: Icon(Icons.person, size: 60, color: Colors.white),
                  ),
                  const SizedBox(height: 16),

                  // 🔹 Username
                  Text(
                    userData?['username'] ?? user!.displayName ?? "No Name",
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // 🔹 Email
                  Text(
                    user!.email ?? "No Email",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 🔹 Member since
                  Text(
                    "Joined: ${user!.metadata.creationTime?.toLocal().toString().split(' ').first ?? "Unknown"}",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // 🔹 Buttons
                  _actionButton(
                    context,
                    label: "Edit Profile",
                    icon: Icons.edit,
                    color: Colors.blueAccent,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Edit Profile Coming Soon")),
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  _actionButton(
                    context,
                    label: "Change Password",
                    icon: Icons.lock,
                    color: Colors.orangeAccent,
                    onTap: () async {
                      if (user?.email != null) {
                        await FirebaseAuth.instance
                            .sendPasswordResetEmail(email: user!.email!);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text("Password reset link sent")),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  _actionButton(
                    context,
                    label: "Logout",
                    icon: Icons.logout,
                    color: Colors.redAccent,
                    onTap: () async {
                      await FirebaseAuth.instance.signOut();
                      if (context.mounted) {
                        Navigator.pushReplacementNamed(context, '/login');
                      }
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget _actionButton(BuildContext context,
      {required String label,
      required IconData icon,
      required Color color,
      required VoidCallback onTap}) {
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
}
